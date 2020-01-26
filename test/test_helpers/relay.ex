defmodule SagAppointments.TestHelpers.Relay do
  use GenServer

  @wait_rounds 5

  def start_link(wait_period) do
    GenServer.start_link(__MODULE__, wait_period)
  end

  def init(wait_period), do: {:ok, %{wait_period: wait_period, wait_rounds: 0}}
  
  def send_message(relay, message, receiver, sync \\ :async) do
    case sync do
      :async -> GenServer.call(relay, {receiver, message})
      :sync -> GenServer.call(receiver, message)
    end
  end

  def handle_call({who, request}, from, state) do
    GenServer.cast(who, Map.put(request, :from, self()))
    Process.send_after(self(), :check, div(state.wait_period, @wait_rounds))
    {:noreply, Map.put_new(state, :from, from)}
  end

  def handle_cast(reply, state) do
    {:noreply, Map.put(state, :reply, reply)}
  end

  def handle_info(:check, state) do
    case Map.fetch(state, :reply) do
      {:ok, reply} ->
        GenServer.reply(Map.fetch!(state, :from), {:ok, reply})
        {:noreply, clean_state(state)}

      :error ->
        if Map.fetch!(state, :wait_rounds) == @wait_rounds do
          GenServer.reply(Map.fetch!(state, :from), {:error, :no_response})
          {:noreply, clean_state(state)}
        else
          Process.send_after(self(), :check, div(state.wait_period, @wait_rounds))
          {:noreply, Map.update!(state, :wait_rounds, &(&1 + 1))}
        end
    end
  end

  defp clean_state(state) do
    state |> Map.drop([:from, :reply]) |> Map.put(:wait_rounds, 0)
  end
end
