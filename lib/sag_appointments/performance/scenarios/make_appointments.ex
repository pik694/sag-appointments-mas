defmodule SagAppointments.Performance.Scenarios.MakeAppointments do
  def init(opts) do
    index = Keyword.fetch!(opts, :index)
    runs = Keyword.fetch!(opts, :runs)

    Process.send(self(), {:run, runs}, [:noconnect])
    {:ok, index}
  end

  def handle_info({:run, 0}, index), do: {:stop, :normal, index}

  def handle_info({:run, runs}, index) do
    {:ok, events} = run()

    :ok =
      events
      |> Enum.map(fn event -> Map.put(event, :runner_index, index) end)
      |> Enum.each(fn event ->
        GenServer.cast(SagAppointments.Performance.RunnerManager, {:stats, event})
      end)

    Process.send(self(), {:run, runs - 1}, [:noconnect])
    {:noreply, index}
  end

  def run() do
    from = Timex.shift(Timex.today(), days: Enum.random(1..7))
    until = Timex.shift(from, days: Enum.random(1..7))
    field = Enum.random(["Pediatra", "Laryngolog", "Okulista"])
    region = Enum.random([nil, "Warszawa", "Pruszków", "Grodzisk Mazowiecki", "Piaseczno"])

    opts = [from: from, until: until, field: field]

    opts =
      case region do
        nil -> opts
        r -> [{:region, r} | opts]
      end

    {query_event, result} =
      run_measured(:query, fn -> SagAppointments.get_available_slots(opts) end)

    add_events =
      case result do
        {:ok, results} ->
          {doctor_id, slot, user_id} = prepare_add_appointment(results)

          {event, _} =
            run_measured(:add, fn -> SagAppointments.add_visit(user_id, doctor_id, slot) end)

          [event]

        {:error, _} ->
          []
      end

    {:ok, [query_event] ++ add_events}
  end

  def run_measured(method, f) do
    start = :os.system_time(:millisecond)
    result = f.()
    finish = :os.system_time(:millisecond)

    query_result =
      case result do
        {:ok, _} -> :ok
        {:error, _} -> :error
      end

    {%{method: method, start: start, end: finish, result: query_result}, result}
  end

  def prepare_add_appointment([result | _]) do
    {result.doctor_id, List.first(result.slots), Enum.random(1..5)}
  end
end
