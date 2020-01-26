defmodule SagAppointments.DoctorTest do
  use ExUnitFixtures
  use ExUnit.Case, async: false

  alias SagAppointments.TestHelpers.Relay
  alias SagAppointments.Doctor
  alias SagAppointments.Doctor.Schedule
  alias SagAppointments.Message

  @default_days %{1 => %{start: 10, end: 17}, 3 => %{start: 14, end: 15}}
  @doctor %{
    name: "John",
    surname: "Smith",
    field: "Pediatrician",
    clinic: "XYZ",
    working_hours: @default_days,
    visit_time: 10
  }

  deffixture relay() do
    {:ok, relay} = Relay.start_link(100)
    relay
  end

  deffixture available_slots_query() do
    next_monday = Timex.shift(Timex.today(), days: 8 - Timex.weekday(Timex.today()))
    %Message{message: {:query, :slots}, content: {next_monday, next_monday}}
  end
  
  deffixture schedule() do
    {:ok, schedule} = Schedule.start_link({@doctor.clinic, @doctor.name, @doctor.surname})
    schedule
  end

  deffixture doctor(schedule) do
    {:ok, doctor} = Doctor.start_link(Map.put_new(@doctor, :schedule, schedule) |> Map.to_list())
    doctor
  end

  deffixture available_slot(doctor, available_slots_query, relay) do 
    {:ok, %Message{content: [slot| _]}} = Relay.send_message(relay, available_slots_query, doctor)
    slot
  end

  @tag fixtures: [:available_slots_query, :doctor, :relay]
  test "doctor can fetch available slots when state is empty", %{
    relay: relay,
    doctor: doctor,
    available_slots_query: query
  } do
    {:ok, %Message{message: {:reply, :slots}} = reply} = Relay.send_message(relay, query, doctor)
    assert is_list(reply.content)
  end

  @tag fixtures: [:available_slots_query, :doctor, :schedule, :relay]
  test "doctor can fetch available slots when state is not empty", %{
    relay: relay,
    doctor: doctor,
    available_slots_query: query,
    schedule: schedule
  } do
    {:ok, %Message{content: all_slots}} = Relay.send_message(relay, query, doctor)
    Schedule.add_appointment(schedule, appointment(hd(all_slots)))

    {:ok, %Message{content: slots}} = GenServer.call(relay, {doctor, query})
    assert slots == tl(all_slots)
  end

  @tag fixtures: [:available_slots_query, :doctor, :schedule, :relay]
  test "doctor fetches empty list when there is no available slot", %{
    relay: relay,
    doctor: doctor,
    available_slots_query: query,
    schedule: schedule
  } do
    {:ok, %Message{content: all_slots}} =  Relay.send_message(relay, query, doctor)

    all_slots
    |> Enum.map(&appointment/1)
    |> Enum.each(&Schedule.add_appointment(schedule, &1))

    {:ok, %Message{content: slots}} = Relay.send_message(relay, query, doctor)
    assert Enum.empty?(slots)
  end

  @tag fixtures: [:available_slots_query, :available_slot, :doctor, :relay]
  test "doctor can add appointment", %{
    relay: relay,
    doctor: doctor,
    available_slots_query: query,
    available_slot: slot,
  } do 

    message = %Message{message: :add_appointment, content: {slot, "Jake Jones"}}

    :ok = Relay.send_message(relay, message, doctor, :sync) 
    {:ok, %Message{content: slots}} = Relay.send_message(relay, query, doctor)
    
    assert not Enum.member?(slots, slot)

  end
  
  defp appointment(slot), do: %Schedule.Appointment{slot: slot, patient: "Jake Jones"}
end
