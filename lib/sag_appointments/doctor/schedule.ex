defmodule SagAppointments.Doctor.Schedule do
  use GenServer

  alias SagAppointments.Appointment

  defstruct [history: [], future: []]

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def add_appointment(schedule, %Appointment{} = appointment) do
    GenServer.cast(schedule, {:add, appointment})
  end
  
  def delete_appointment(schedule, id) do
    GenServer.cast(schedule, {:delete, id})
  end

  def get_history(schedule) do
    GenServer.call(schedule, :get_history)
  end

  def get_future_appointments(schedule) do
    GenServer.call(schedule, :get_future)
  end

  #### GEN SERVER 
  def init(_) do
    {:ok, struct(__MODULE__)}
  end

  def handle_call(:get_history, _from, %{history: history} = state) do
    {:reply, {:ok, history}, state}
  end
  
  def handle_call(:get_future, _from, %{future: future} = state) do
    {:reply, {:ok, future}, state}
  end

  def handle_cast({:add, %Appointment{} = appointment}, state) do

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

  def handle_cast({:delete, id}, state) do
    {:ok, updated_state} = move_from_future_to_history(state)
    
    updated_state = Map.update!(
      updated_state,
      :future,
      &Enum.filter(&1, fn %{id: appointment_id} -> appointment_id != id end)
    )

    {:noreply, updated_state}
  end

  defp move_from_future_to_history(%__MODULE__{history: history, future: future} = state) do
    now = Timex.now()

    {new_history, updated_future} =
      Enum.split_while(future, fn %{slot: slot} ->
        Timex.compare(slot, now) < 1
      end)

    updated_history = history ++ new_history

    updated_state = Map.merge(state, %{history: updated_history, future: updated_future})
    {:ok, updated_state}
  end

end

defimpl String.Chars, for: SagAppointments.Doctor.Schedule.Appointment do
  def to_string(%SagAppointments.Doctor.Schedule.Appointment{id: id, patient: patient, slot: slot}) do
    "Appointment(id: #{id}, patient: #{patient}, slot: #{slot})"
  end
end
