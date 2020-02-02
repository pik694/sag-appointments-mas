defmodule SagAppointments.Performance.RunnerManager do
  require Logger
  use GenServer

  def start_link_all_scenarios(scenarios) do
    GenServer.start_link(__MODULE__, scenarios, name: __MODULE__)
  end

  def init(scenarios) do
    Process.flag(:trap_exit, true)
    Logger.debug("Starting load test with #{length(scenarios)}")

    runners =
      scenarios
      |> Enum.with_index()
      |> Enum.map(fn {{scenario, opts}, index} ->
         IO.inspect("#{inspect(scenario)}, #{inspect(opts)}, #{index}")
        {:ok, pid} = GenServer.start_link(scenario, [{:index, index} | opts])
        {index, pid}
      end)

    {:ok, %{runners: runners, start_time: System.monotonic_time(:millisecond), events: []}}
  end

  def handle_info(
        {:EXIT, from_pid, _reason},
        %{runners: [{_last_seqnum, from_pid} = last_sender]} = state
      ) do
    _ =
      Logger.info("Senders are all done, last sender: #{inspect(last_sender)}. Stopping manager")

    write_stats(state)
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, from_pid, reason}, %{runners: runners} = state) do
    case Enum.find(runners, fn {_seqnum, pid} -> pid == from_pid end) do
      nil ->
        {:stop, {:unknown_child_exited, from_pid, reason}, state}

      {_done_seqnum, done_pid} = done_sender ->
        remaining_senders = Enum.filter(runners, fn {_seqnum, pid} -> pid != done_pid end)
        _ = Logger.info("Sender #{inspect(done_sender)} done. Manager continues...")
        {:noreply, %{state | runners: remaining_senders}}
    end
  end

  def handle_cast({:stats, event}, state) do
    {:noreply, %{state | events: [event | state.events]}}
  end

  defp write_stats(%{events: events} = _state) do
    destfile = Path.join("/tmp", "per_results_#{:os.system_time(:seconds)}.json")
    :ok = File.write(destfile, Jason.encode!(events))
    Logger.info("Performance stats written to: #{inspect(destfile)}")
    :ok
  end
end
