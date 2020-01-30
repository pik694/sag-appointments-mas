defmodule SagAppointments.Clinic do
  require Logger
  use GenServer

  @cleanup_period 100
  @wait_threshold 500

  defstruct [:name, :supervisor, query_id: 0, queries: %{}]

  def start_link(name, supervisor) do
    GenServer.start_link(__MODULE__, {name, supervisor})
  end

  def init({name, supervisor}) do
    Process.send_after(self(), :clean_stale_queries, @cleanup_period)
    {:ok, %__MODULE__{name: name, supervisor: supervisor}}
  end

  def handle_cast({from, request}, state) do
    children = SagAppointments.Clinic.Supervisor.doctors(state.supervisor)
    {state_incremented, query_id} = get_unique_query_id(state)

    updated_state =
      build_query(query_id, children, from, request)
      |> exec()
      |> update_state(state_incremented)

    {:noreply, updated_state}
  end

  def handle_cast({:reply, query_id, from, response}, state) do
    case handle_response(state, query_id, from, response) do
      {:ok, updated_state, {to, response}} ->
        Logger.info("Received response from #{inspect(from)}")
        Logger.info("Sending response to #{inspect(to)}")
        GenServer.cast(to, response)
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
    GenServer.cast(to, response)
  end

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

  defp build_response(state, %{request: request, responses: responses, from: {query_id, from}}) do
    filtered_responses =
      Enum.filter(responses, fn
        :irrelevant -> false
        _ -> true
      end)

    {from,
     {:reply, query_id, self(), do_build_response(elem(request, 0), filtered_responses, state)}}
  end

  defp do_build_response(_, [], _), do: :irrelevant

  defp do_build_response(:add_appointment, [response], state) do
    %{clinic: state.name, responses: [response]}
  end

  defp do_build_response(:query_by_patient, responses, state) do
    response =
      responses
      |> Enum.map(fn {doctor_id, doctor_name, doctor_field, slots} ->
        %{
          doctor_id: doctor_id,
          doctor_name: doctor_name,
          doctor_field: doctor_field,
          slots: slots
        }
      end)
      |> Enum.filter(fn %{slots: slots} -> not Enum.empty?(slots) end)

    %{clinic: state.name, responses: response}
  end

  defp do_build_response(:query_available, responses, state) do
    response =
      responses
      |> Enum.map(fn {doctor_id, doctor_name, slots} ->
        %{doctor_id: doctor_id, doctor_name: doctor_name, slots: slots}
      end)
      |> Enum.filter(fn %{slots: slots} -> not Enum.empty?(slots) end)

    %{clinic: state.name, responses: response}
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
