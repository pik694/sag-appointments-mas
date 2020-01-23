defmodule SagAppointments.Doctor.ScheduleTest do
  use ExUnitFixtures
  use ExUnit.Case

  alias SagAppointments.Doctor.Schedule
  alias SagAppointments.Doctor.Schedule.Appointment

  setup do
    {:ok, pid} = SagAppointments.Doctor.Schedule.start_link({"XYZ", "John", "Smith"})
    {:ok, schedule: pid}
  end

  deffixture appointments do
    future = Timex.shift(Timex.now(), days: 10)
    past = Timex.shift(Timex.now(), days: -2)

    [
      %Appointment{slot: future, patient: "John Smith"},
      %Appointment{slot: past, patient: "John Smith"}
    ]
  end

  test "clean state has no appointments", %{schedule: schedule} do
    assert Schedule.get_history(schedule) == {:ok, []}
    assert Schedule.get_taken_slots(schedule) == {:ok, []}
  end

  @tag fixtures: [:appointments]
  test "can add an appointments", %{schedule: schedule, appointments: [appointment | _]} do
    Schedule.add_appointment(schedule, appointment)

    assert Schedule.get_history(schedule) == {:ok, []}
    assert Schedule.get_taken_slots(schedule) == {:ok, [appointment.slot]}
  end
end
