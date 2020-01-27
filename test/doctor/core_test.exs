defmodule SagAppointments.Doctor.CoreTest do
  use ExUnitFixtures
  use ExUnit.Case, async: true
  use Timex

  alias SagAppointments.{Doctor, Appointment}
  import SagAppointments.Doctor.Core
  
  @default_days %{1 => %{start: 9, end: 17}, 3 => %{start: 12, end: 14}} 
  @visit_time 10

  deffixture init_state() do
    struct!(Doctor,
      name: "John Smith",
      field: "Pediatrician",
      forward_slots: Timex.Duration.from_weeks(2),
      working_hours: @default_days,
      visit_time: @visit_time
    )
  end

  deffixture appointments() do
    
    past_day_morning = Timex.shift(Timex.today, days: -7) |> Timex.to_naive_datetime() |> Timex.shift(hours: 9)
    next_monday_morning = Timex.shift(Timex.today, days: 8 - Timex.weekday(Timex.today)) |> Timex.to_naive_datetime() |> Timex.shift(hours: 9)

    {[
      %Appointment{id: 1, patient: 1, slot: past_day_morning},
      %Appointment{id: 2, patient: 2, slot: Timex.shift(past_day_morning, minutes: @visit_time)},
      %Appointment{id: 3, patient: 1, slot: Timex.shift(past_day_morning, minutes: 2 * @visit_time)},
    ],
    [
      %Appointment{id: 4, patient: 1, slot: next_monday_morning},
      %Appointment{id: 5, patient: 2, slot: Timex.shift(next_monday_morning, minutes: @visit_time)},
      %Appointment{id: 6, patient: 1, slot: Timex.shift(next_monday_morning, minutes: 2 * @visit_time)},
    ]}
  end

  @tag fixtures: [:appointments]
  test "can filter appointments by patient", %{appointments: {last, future}} do
    
    filtered = get_appointments_for_patient(last, future, 1)
    assert length(filtered) == 4
    assert Enum.all?(filtered, fn %{patient: id} -> id == 1 end)

  end 


  @tag fixtures: [:init_state, :appointments]
  test "can get available slots for a day", %{init_state: state, appointments: {_, future}} do

    next_monday = Timex.shift(Timex.today, days: 8 - Timex.weekday(Timex.today))
    available = available_slots(state, future, Timex.now, day: next_monday)
    
    assert length(available) == 8 * 6 - 3

  end

  @tag fixtures: [:init_state, :appointments]
  test "can get available slots for period", %{init_state: state, appointments: {_, future}} do

    next_monday = Timex.shift(Timex.today, days: 8 - Timex.weekday(Timex.today))
    next_wednesday = Timex.shift(Timex.today, days: 8 - Timex.weekday(Timex.today) + 2)
    
    available = available_slots(state, future, Timex.now, from: next_monday, until: next_wednesday)
    
    assert length(available) == (8 + 2) * 6 - 3

  end

  @tag fixtures: [:init_state]
  test "restricts available slots query to valid period", %{init_state: state} do

    next_monday = Timex.shift(Timex.today, days: 8 - Timex.weekday(Timex.today))
    
    available = available_slots(state, [], next_monday, from: Timex.shift(next_monday, days: -200), until: Timex.shift(next_monday, days: 200))
    
    assert length(available) == 2 * (8 + 2) * 6

  end

  @tag fixtures: [:init_state, :appointments]
  test "can create an appointment", %{init_state: state, appointments: {past, future}} do

    past_slot = hd(past) |> Map.fetch!(:slot) 
    future_slot = hd(future) |> Map.fetch!(:slot)

    next_monday = Timex.shift(Timex.today, days: 8 - Timex.weekday(Timex.today))
    
    assert try_create_appointment(state, [], next_monday, future_slot, 1, 4) == {:ok, hd(future)}
    assert try_create_appointment(state, future, next_monday, future_slot, 1, 4) == :error
    assert try_create_appointment(state, [], next_monday, past_slot, 1, 4) == :error 


  end


end
