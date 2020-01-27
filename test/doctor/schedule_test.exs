defmodule SagAppointments.Doctor.ScheduleTest do
  use ExUnitFixtures
  use ExUnit.Case

  alias SagAppointments.Doctor.Schedule
  alias SagAppointments.Appointment

  setup do
    {:ok, pid} = SagAppointments.Doctor.Schedule.start_link()
    {:ok, schedule: pid}
  end

  deffixture appointments do
    future = Timex.shift(Timex.now(), days: 10)
    past = Timex.shift(Timex.now(), days: -2)

    [
      %Appointment{id: 1, slot: future, patient: "John Smith"},
      %Appointment{id: 2, slot: past, patient: "John Smith"}
    ]
  end

  test "clean state has no appointments", %{schedule: schedule} do
    assert Schedule.get_history(schedule) == {:ok, []}
    assert Schedule.get_future_appointments(schedule) == {:ok, []}
  end

  @tag fixtures: [:appointments]
  test "can add an appointments", %{schedule: schedule, appointments: [appointment | _]} do
    Schedule.add_appointment(schedule, appointment)

    assert Schedule.get_history(schedule) == {:ok, []}
    assert Schedule.get_future_appointments(schedule) == {:ok, [appointment]}
  end

  @tag fixtures: [:appointments]
  test "can delete an appointments", %{schedule: schedule, appointments: [appointment | _]} do
    Schedule.add_appointment(schedule, appointment)

    Schedule.delete_appointment(schedule, appointment.id)

    assert Schedule.get_history(schedule) == {:ok, []}
    assert Schedule.get_future_appointments(schedule) == {:ok, []}
  end
end
