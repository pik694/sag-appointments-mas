defmodule SagAppointments.Doctor.CoreTest do
  use ExUnitFixtures
  use ExUnit.Case, async: true
  use Timex

  alias SagAppointments.Doctor
  import SagAppointments.Doctor.Core

  @default_days %{1 => %{start: 10, end: 17}, 3 => %{start: 14, end: 15}}
  @monday Timex.shift(Timex.zero(), days: 2)

  deffixture init_state() do
    struct!(Doctor,
      name: "John",
      surname: "Smith",
      field: "Pediatrician", 
      clinic: "XYZ",
      working_hours: @default_days,
      visit_time: 10
    )
  end

  @tag fixtures: [:init_state]
  test "computes slots for one day", %{init_state: state} do
    assert length(slots(state, @monday)) == 7 * 6
    assert slots(state, Timex.shift(@monday, days: 1)) == []
    assert length(slots(state, Timex.shift(@monday, days: 2))) == 6
  end

  @tag fixtures: [:init_state]
  test "computes available slots", %{init_state: state} do
    [h | tail] = slots(state, @monday)
    taken_slots = [h]

    assert available_slots(state, taken_slots, @monday) == tail

    assert available_slots(state, taken_slots, Timex.shift(@monday, days: 1)) ==
             slots(state, Timex.shift(@monday, days: 1))

    assert available_slots(state, taken_slots, Timex.shift(@monday, days: 2)) ==
             slots(state, Timex.shift(@monday, days: 2))
  end
end
