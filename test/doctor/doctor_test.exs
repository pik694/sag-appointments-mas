defmodule SagAppointments.DoctorTest do
  use ExUnitFixtures
  use ExUnit.Case, async: true

  alias SagAppointments.TestHelpers.Relay
  alias SagAppointments.Doctor
  alias SagAppointments.Doctor.Schedule

  @default_days %{1 => %{start: 10, end: 17}, 3 => %{start: 14, end: 15}}
  @doctor %{
    id: 0,
    name: "John Smith",
    field: "Pediatrician",
    forward_slots: Timex.Duration.from_weeks(4),
    working_hours: @default_days,
    visit_time: 10
  }

  deffixture schedule() do
    {:ok, schedule} = Schedule.start_link()
    schedule
  end

  deffixture doctor(schedule) do
    {:ok, doctor} = Doctor.start_link(Map.put_new(@doctor, :schedule, schedule) |> Map.to_list())
    doctor
  end

  @tag fixtures: [:doctor, :relay]
  test "doctor can fetch available slots when state is empty", %{
    relay: relay,
    doctor: doctor
  } do
    {:ok, {doctor_id, doctor_name, slots}} =
      Relay.send_message(relay, {:query_available, day: Timex.today()}, doctor)

    assert is_list(slots)
    assert doctor_id == @doctor.id && doctor_name == @doctor.name

    assert Relay.send_message(
             relay,
             {:query_available, name: "Jack Jones", day: Timex.today()},
             doctor
           ) == {:ok, :irrelevant}
  end

  @tag fixtures: [:doctor, :relay]
  test "doctor does not fetch available slots when query irrelevant", %{
    relay: relay,
    doctor: doctor
  } do
    assert Relay.send_message(
             relay,
             {:query_available, name: "Jack Jones", day: Timex.today()},
             doctor
           ) == {:ok, :irrelevant}

    assert Relay.send_message(
             relay,
             {:query_available, field: "Dentist", day: Timex.today()},
             doctor
           ) == {:ok, :irrelevant}
  end

  @tag fixtures: [:doctor, :relay]
  test "doctor can add an appointment", %{
    relay: relay,
    doctor: doctor
  } do
    query_opts = [from: Timex.today(), until: Timex.shift(Timex.today(), weeks: 1)]

    {:ok, {doctor_id, doctor_name, [slot | _]}} =
      Relay.send_message(relay, {:query_available, query_opts}, doctor)

    {:ok, {:ok, _appointment_id}} =
      Relay.send_message(relay, {:add_appointment, doctor_id, 0, slot}, doctor)

    {:ok, {^doctor_id, ^doctor_name, slots}} =
      Relay.send_message(relay, {:query_available, query_opts}, doctor)

    assert not Enum.member?(slots, slot)
  end

  @tag fixtures: [:doctor, :relay]
  test "doctor can delete an appointment", %{
    relay: relay,
    doctor: doctor
  } do
    query_opts = [from: Timex.today(), until: Timex.shift(Timex.today(), weeks: 1)]

    {:ok, {doctor_id, _, [slot | _]}} =
      Relay.send_message(relay, {:query_available, query_opts}, doctor)

    {:ok, {:ok, appointment_id}} =
      Relay.send_message(relay, {:add_appointment, doctor_id, 0, slot}, doctor)

    Relay.send_message(relay, {:delete_appointment, appointment_id}, doctor)
    # just delete some non-existent appointment
    Relay.send_message(relay, {:delete_appointment, -100}, doctor)

    {:ok, {_, _, slots}} = Relay.send_message(relay, {:query_available, query_opts}, doctor)

    assert Enum.member?(slots, slot)
  end
end
