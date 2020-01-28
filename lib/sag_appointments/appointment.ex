defmodule SagAppointments.Appointment do
  defstruct [:id, :slot, :patient]
end

defimpl String.Chars, for: SagAppointments.Appointment do
  def to_string(%SagAppointments.Appointment{id: id, patient: patient, slot: slot}) do
    "Appointment(id: #{id}, patient: #{patient}, slot: #{slot})"
  end
end
