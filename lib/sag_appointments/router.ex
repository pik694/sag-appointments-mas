defmodule SagAppointments.Router do
  require Logger
  use GenServer

  @cleanup_period 100
  @wait_threshold 1000

  defstruct query_id: 0, queries: %{}

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_available_slots(opts) do
    GenServer.call(__MODULE__, {:query_available, opts})
  end

  def get_visits_for_user(id) do
    GenServer.call(__MODULE__, {:query_by_patient, id})
  end

  def delete_vist(visit_id) do
    GenServer.call(__MODULE__, {:delete_appointment, visit_id})
  end

  def add_visit(patient_id, doctor_id, slot) do
    GenServer.call(__MODULE__, {:add_appointment, doctor_id, patient_id, slot})
  end

  def init(nil) do
    Process.send_after(self(), :clean_stale_queries, @cleanup_period)
    {:ok, %__MODULE__{}}
  end

  def handle_call(request, from, state) do
    if filter_request(state, request) do
      children = regions()
      {state_incremented, query_id} = get_unique_query_id(state)

      updated_state =
        build_query(query_id, children, from, request)
        |> exec()
        |> update_state(state_incremented)

      {:noreply, updated_state}
    else
      GenServer.reply(from, {:ok, :irrelevant})
      {:noreply, state}
    end
  end

  defp regions() do
    Supervisor.which_children(SagAppointments.Supervisor)
    |> Enum.filter(fn {id, _, _, _} -> is_integer(id) end)
    |> Enum.map(fn {_, pid, _, _} -> Supervisor.which_children(pid) end)
    |> List.flatten()
    |> Enum.filter(fn {id, pid, _, _} -> id == :region && is_pid(pid) end)
    |> Enum.map(&elem(&1, 1))
  end

  def handle_cast({:reply, query_id, from, response}, state) do
    case handle_response(state, query_id, from, response) do
      {:ok, updated_state, {to, response}} ->
        Logger.info("Received response from #{inspect(from)}")
        Logger.info("Sending response to #{inspect(to)}")
        GenServer.reply(to, response)
        {:noreply, updated_state}

      {:ok, updated_state} ->
        Logger.info("Received response from #{inspect(from)}")
        {:noreply, updated_state}

      _ ->
        Logger.info("Received irrelevant response from #{inspect(from)}")
        {:noreply, state}
    end
  end

  def handle_info(:clean_stale_queries, state) do
    past_threshold = Timex.shift(Timex.now(), milliseconds: -@wait_threshold)
    Logger.debug("Cleaning stale queries")

    {stale_queries, valid_queries} =
      Enum.split_with(state.queries, fn {_, %{query_time: query_time}} ->
        Timex.compare(query_time, past_threshold) < 1
      end)

    Logger.debug("Found #{length(stale_queries)} stale queries")

    Enum.each(stale_queries, &send_response(state, &1))

    Process.send_after(self(), :clean_stale_queries, @cleanup_period)
    {:noreply, Map.put(state, :queries, Map.new(valid_queries))}
  end

  def send_response(state, {_query_id, query}) do
    {to, response} = build_response(state, query)
    GenServer.reply(to, response)
  end

  defp filter_request(%{name: region_name}, {:query_available, opts}) do
    case Keyword.fetch(opts, :region) do
      :error -> true
      {:ok, region} -> region == region_name
    end
  end

  defp filter_request(_, _), do: true

  defp handle_response(state, query_id, from, response) do
    with {:ok, query} <- Map.fetch(state.queries, query_id),
         true <- Enum.member?(query.waiting_for_response, from) do
      updated_query =
        query
        |> Map.update!(:waiting_for_response, &List.delete(&1, from))
        |> Map.update!(:responses, &:erlang.++(&1, [response]))

      if should_response?(updated_query) do
        updated_state = Map.update!(state, :queries, &Map.delete(&1, query_id))
        {:ok, updated_state, build_response(state, updated_query)}
      else
        updated_state = Map.update!(state, :queries, &Map.put(&1, query_id, updated_query))
        {:ok, updated_state}
      end
    end
  end

  defp should_response?(query) do
    request = elem(query.request, 0)
    Enum.empty?(query.waiting_for_response) || should_response?(request, query)
  end

  defp should_response?(:add_appointment, query) do
    length(query.responses) > 0
  end

  defp should_response?(_, _), do: false

  defp build_response(state, %{responses: responses, from: from}) do
    filtered_responses =
      responses
      |> Enum.filter(fn
        :irrelevant -> false
        _ -> true
      end)
      |> Enum.filter(fn
        %{responses: []} -> false
        _ -> true
      end)

    {from, {:ok, do_build_response(filtered_responses, state)}}
  end

  defp do_build_response([], _), do: :irrelevant

  defp do_build_response(responses, _) do
    responses
  end

  defp build_query(query_id, children, from, request) do
    {query_id,
     %{
       waiting_for_response: children,
       query_time: Timex.now(),
       responses: [],
       request: request,
       from: from
     }}
  end

  defp exec({query_id, query}) do
    query.waiting_for_response
    |> Enum.each(&GenServer.cast(&1, {{query_id, self()}, query.request}))

    {query_id, query}
  end

  defp update_state({query_id, query}, state) do
    Map.update!(state, :queries, &Map.put_new(&1, query_id, query))
  end

  defp get_unique_query_id(state) do
    {Map.update!(state, :query_id, &:erlang.+(&1, 1)), Map.fetch!(state, :query_id)}
  end
end
