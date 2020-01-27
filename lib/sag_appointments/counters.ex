defmodule SagAppointments.Counters do
  def init do
    __MODULE__ = :ets.new(__MODULE__, [:public, :named_table])
    true = :ets.insert_new(__MODULE__, {:appointment, 0})
    true = :ets.insert_new(__MODULE__, {:doctor, 0})
    :ok
  end

  def appointment_id, do: :ets.update_counter(__MODULE__, :appointment, 1)
  def doctor_id, do: :ets.update_counter(__MODULE__, :doctor, 1)
end
