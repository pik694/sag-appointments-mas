defmodule SagAppointments.Performance.Scenarios.QueryAvailable do
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

    start = :os.system_time(:millisecond)
    result = SagAppointments.get_available_slots(opts)
    finish = :os.system_time(:millisecond)

    result =
      case result do
        {:ok, _} -> :ok
        {:error, _} -> :error
      end

    {:ok, [%{method: :query, opts: Map.new(opts), start: start, end: finish, result: result}]}
  end
end
