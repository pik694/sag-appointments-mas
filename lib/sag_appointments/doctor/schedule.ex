defmodule SagAppointments.Doctor.Schedule do
  require Logger
  use GenServer

  defstruct [:name, history: [], future: []]

  defmodule Appointment do
    defstruct [:slot, :patient]
  end

  def start_link({clinic, name, surname}) do
    GenServer.start_link(__MODULE__, "#{clinic}:#{name}:#{surname}")
  end

  def add_appointment(schedule, appointment) do
    GenServer.cast(schedule, {:add_appointment, appointment})
  end

  def get_history(schedule) do
    GenServer.call(schedule, :get_history)
  end

  def get_taken_slots(schedule) do
    GenServer.call(schedule, :get_taken_slots)
  end

  #### GEN SERVER 
  def init(name) do
    Logger.info("Starting schedule #{name}")
    {:ok, struct(__MODULE__, name: name)}
  end

  def handle_call(:get_history, _from, %{history: history} = state) do
    {:reply, {:ok, history}, state}
  end

  def handle_call(:get_taken_slots, _from, %{future: scheduled} = state) do
    taken_slots = Enum.map(scheduled, fn %Appointment{slot: slot} -> slot end)
    {:reply, {:ok, taken_slots}, state}
  end

  def handle_cast({:add_appointment, %Appointment{} = appointment}, %{name: name} = state) do
    Logger.info("Adding appointment to #{name} schedule #{appointment}")

    {:ok, updated_state} = move_from_future_to_history(state)

    {:noreply,
     Map.update!(
       updated_state,
       :future,
       &Enum.sort([appointment | &1], fn %{slot: l_slot}, %{slot: r_slot} ->
         l_slot < r_slot
       end)
     )}
  end

  def handle_cast({:drop_appointment, slot}, %{name: name} = state) do
    Logger.info("Deleting visit from #{name} schedule at #{slot}")

    {:ok, updated_state} = move_from_future_to_history(state)

    case drop_slot(updated_state.future, slot) do
      {:ok, updated_future} ->
        Logger.info("Successfully dropped an appointment")
        {:noreply, Map.put(updated_state, :future, updated_future)}

      :error ->
        Logger.info("Did not find appointment at given slot")
        {:noreply, updated_state}
    end
  end

  defp move_from_future_to_history(%__MODULE__{history: history, future: future} = state) do
    Logger.debug("Moving future appointments to history in schedule")
    now = Timex.now()
    {new_history, updated_future} = Enum.split_while(future, fn %{slot: slot} -> slot < now end)
    updated_history = history ++ new_history
    Logger.debug("Moved #{length(new_history)} appointments")

    updated_state = Map.merge(state, %{history: updated_history, future: updated_future})
    {:ok, updated_state}
  end

  defp drop_slot(appointments, slot) do
    case do_drop_slot(appointments, slot) do
      ^appointments -> :error
      updated_appointments -> {:ok, updated_appointments}
    end
  end

  defp do_drop_slot([], _slot), do: []

  defp do_drop_slot([h | t], slot) do
    if h.slot == slot do
      t
    else
      [h | do_drop_slot(t, slot)]
    end
  end
end

defimpl String.Chars, for: SagAppointments.Doctor.Schedule.Appointment do
  def to_string(%SagAppointments.Doctor.Schedule.Appointment{patient: patient, slot: slot}) do
    "Appointment(#{patient}, #{slot})"
  end
end
