defmodule SagAppointments.ClinicTest do
  use ExUnitFixtures
  use ExUnit.Case, async: true

  alias SagAppointments.TestHelpers.Relay
  alias SagAppointments.Clinic

  def next_monday(), do: Timex.shift(Timex.today(), days: 8 - Timex.weekday(Timex.today()))

  deffixture clinic(doctors_spec) do
    {:ok, supervisor} = Clinic.Supervisor.start_link("XYZ", doctors_spec)

    {:clinic, clinic, _, _} =
      supervisor
      |> Supervisor.which_children()
      |> Enum.find(fn
        {:clinic, _, _, _} -> true
        _ -> false
      end)

    clinic
  end

  @tag fixtures: [:clinic, :relay]
  test "clinic can query its doctors for available slots", %{clinic: clinic, relay: relay} do
    {:ok, %{clinic_name: "XYZ"}} =
      Relay.send_message(relay, {:query_available, day: next_monday()}, clinic)

    assert Relay.send_message(
             relay,
             {:query_available, name: "Dr Dolittle", day: next_monday()},
             clinic
           ) == {:ok, :irrelevant}
  end

  @tag fixtures: [:clinic, :relay]
  test "fetches empty when no slot found", %{clinic: clinic, relay: relay} do
    some_past_date = Timex.shift(Timex.today(), months: -1)

    {:ok, %{clinic_name: "XYZ", responses: responses}} =
      Relay.send_message(
        relay,
        {:query_available, day: some_past_date},
        clinic
      )

    assert Enum.empty?(responses)
  end

  @tag fixtures: [:clinic, :relay]
  test "can add appointment", %{clinic: clinic, relay: relay} do
    {:ok, %{responses: [response | _]}} =
      Relay.send_message(
        relay,
        {:query_available, day: next_monday()},
        clinic
      )

    {:ok, %{clinic_name: "XYZ", result: {:ok, appointemnt_id}}} =
      Relay.send_message(
        relay,
        {:add_appointment, response.doctor_id, 0, hd(response.slots)},
        clinic
      )

    assert is_integer(appointemnt_id)
  end

  @tag fixtures: [:clinic, :relay]
  test "can query appointments by patient", %{clinic: clinic, relay: relay} do
    {:ok, %{responses: [response | _]}} =
      Relay.send_message(
        relay,
        {:query_available, day: next_monday()},
        clinic
      )

    {:ok, %{clinic_name: "XYZ", result: {:ok, _}}} =
      Relay.send_message(
        relay,
        {:add_appointment, response.doctor_id, 0, hd(response.slots)},
        clinic
      )

    {:ok, %{clinic_name: "XYZ", responses: [_]}} =
      Relay.send_message(
        relay,
        {:query_by_patient, 0},
        clinic
      )
  end

  @tag fixtures: [:clinic, :relay]
  test "can delete appointment", %{clinic: clinic, relay: relay} do
    {:ok, %{responses: [response | _]}} =
      Relay.send_message(
        relay,
        {:query_available, day: next_monday()},
        clinic
      )

    {:ok, %{clinic_name: "XYZ", result: {:ok, appointemnt_id}}} =
      Relay.send_message(
        relay,
        {:add_appointment, response.doctor_id, 0, hd(response.slots)},
        clinic
      )

    :no_response =
      Relay.send_message(
        relay,
        {:delete_appointment, appointemnt_id},
        clinic
      )

    {:ok, :irrelevant} =
      Relay.send_message(
        relay,
        {:query_by_patient, 0},
        clinic
      )
  end
end
