defmodule SagAppointments.Appointment do
  
  defstruct [:id, :slot, :patient]

  def init do
    :appointments_id = :ets.new(:appointments_id, [:named_table])
    true = :ets.insert_new(:appointments_id, {:id, 0})
    :ok
  end

  def get_unique_id do
    :ets.update_counter(:appointments_id, :id, 1) 
  end

end

defimpl String.Chars, for: SagAppointments.Appointment do
  def to_string(%SagAppointments.Appointment{id: id, patient: patient, slot: slot}) do
    "Appointment(id: #{id}, patient: #{patient}, slot: #{slot})"
  end
end
