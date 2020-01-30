defmodule SagAppointmentsTest do
  use ExUnitFixtures
  use ExUnit.Case, async: false

  deffixture next_monday() do
    Timex.shift(Timex.today(), days: 8 - Timex.weekday(Timex.today()))
  end

  setup do
    on_exit(fn ->
      children =
        Supervisor.which_children(SagAppointments.Supervisor)
        |> Enum.filter(fn {id, _, _, _} -> is_integer(id) end)

      :ok =
        Enum.each(children, fn {id, _, _, _} ->
          Supervisor.terminate_child(SagAppointments.Supervisor, id)
        end)

      :ok =
        Enum.each(children, fn {id, _, _, _} ->
          Supervisor.restart_child(SagAppointments.Supervisor, id)
        end)
    end)

    :ok
  end

  @tag fixtures: [:next_monday]
  test "can fetch available slots", %{next_monday: next_monday} do
    {:ok, slots} = SagAppointments.get_available_slots(day: next_monday)
    assert length(slots) > 0

    {:ok, slots} = SagAppointments.get_available_slots(day: next_monday, field: "Pediatra")
    assert length(slots) > 0

    {:ok, slots} =
      SagAppointments.get_available_slots(
        day: next_monday,
        name: "Jan Kowalski",
        region: "Warszawa"
      )

    assert length(slots) > 0

    {:error, _} = SagAppointments.get_available_slots(region: "Wrocław", day: next_monday)
  end

  @tag fixtures: [:next_monday]
  test "can add an appointment", %{next_monday: next_monday} do
    {:ok, response} = SagAppointments.get_available_slots(day: next_monday, field: "Pediatra")
    {doctor_id, slot} = extract_slot(response)

    {:ok, visit_id} = SagAppointments.add_visit(0, doctor_id, slot)
    assert is_integer(visit_id)

    {:error, :could_not_succeed} = SagAppointments.add_visit(0, doctor_id, slot)
  end

  @tag fixtures: [:next_monday]
  test "can delete an appointment", %{next_monday: next_monday} do
    {:ok, response} = SagAppointments.get_available_slots(day: next_monday, field: "Pediatra")
    {doctor_id, slot} = extract_slot(response)
    {:ok, visit_id} = SagAppointments.add_visit(0, doctor_id, slot)

    {:ok, :request_confirmed} = SagAppointments.delete_visit(visit_id)

    {:ok, second_visit_id} = SagAppointments.add_visit(0, doctor_id, slot)

    assert visit_id != second_visit_id
  end

  @tag fixtures: [:next_monday]
  test "can list user appointments", %{next_monday: next_monday} do
    {:error, :could_not_succeed} = SagAppointments.get_visits_for_user(0)

    {:ok, response} = SagAppointments.get_available_slots(day: next_monday, field: "Pediatra")
    {doctor_id, slot} = extract_slot(response)
    {:ok, _visit_id} = SagAppointments.add_visit(0, doctor_id, slot)

    {:ok, [%{slots: [visit]}]} = SagAppointments.get_visits_for_user(0)

    assert visit.slot == slot
  end

  defp extract_slot(response) do
    doctor_response = hd(response)
    {doctor_response.doctor_id, hd(doctor_response.slots)}
  end
end
