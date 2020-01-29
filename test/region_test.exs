defmodule SagAppointments.RegionTest do
  use ExUnitFixtures
  use ExUnit.Case, async: true

  alias SagAppointments.TestHelpers.Relay
  alias SagAppointments.Region

  def next_monday(), do: Timex.shift(Timex.today(), days: 8 - Timex.weekday(Timex.today()))

  deffixture region(doctors_spec) do
    region_clinics = [{"ABC", doctors_spec}, {"CDE", doctors_spec}]

    {:ok, supervisor} = Region.Supervisor.start_link({"Region A", region_clinics})

    {:region, region, _, _} =
      supervisor
      |> Supervisor.which_children()
      |> Enum.find(fn
        {:region, _, _, _} -> true
        _ -> false
      end)

    region
  end

  @tag fixtures: [:region, :relay]
  test "can query its doctors for available slots", %{region: region, relay: relay} do
    {:ok, %{region: "Region A"}} =
      Relay.send_message(relay, {:query_available, day: next_monday()}, region)

    assert Relay.send_message(
             relay,
             {:query_available, name: "Dr Dolittle", day: next_monday()},
             region
           ) == {:ok, :irrelevant}
  end

  @tag fixtures: [:region, :relay]
  test "fetches empty when no slot found", %{region: region, relay: relay} do
    some_past_date = Timex.shift(Timex.today(), months: -1)

    {:ok, :irrelevant} =
      Relay.send_message(
        relay,
        {:query_available, day: some_past_date},
        region
      )
  end

  @tag fixtures: [:region, :relay]
  test "can add appointment", %{region: region, relay: relay} do
    {:ok, %{responses: [%{responses: [response | _]} | _]}} =
      Relay.send_message(
        relay,
        {:query_available, day: next_monday()},
        region
      )

    {:ok, %{region: "Region A", responses: [%{responses: [{:ok, appointemnt_id}]}]}} =
      Relay.send_message(
        relay,
        {:add_appointment, response.doctor_id, 0, hd(response.slots)},
        region
      )

    assert is_integer(appointemnt_id)
  end

  @tag fixtures: [:region, :relay]
  test "can query appointments by patient", %{region: region, relay: relay} do
    {:ok, %{responses: [%{responses: [response | _]} | _]}} =
      Relay.send_message(
        relay,
        {:query_available, day: next_monday()},
        region
      )

    {:ok, %{region: "Region A", responses: [%{responses: [{:ok, _}]}]}} =
      Relay.send_message(
        relay,
        {:add_appointment, response.doctor_id, 0, hd(response.slots)},
        region
      )

    {:ok, %{region: "Region A", responses: [_]}} =
      Relay.send_message(
        relay,
        {:query_by_patient, 0},
        region
      )
  end

  @tag fixtures: [:region, :relay]
  test "can delete appointment", %{region: region, relay: relay} do
    {:ok, %{responses: [%{responses: [response | _]} | _]}} =
      Relay.send_message(
        relay,
        {:query_available, day: next_monday()},
        region
      )

    {:ok, %{region: "Region A", responses: [%{responses: [{:ok, appointment_id}]}]}} =
      Relay.send_message(
        relay,
        {:add_appointment, response.doctor_id, 0, hd(response.slots)},
        region
      )

    :no_response =
      Relay.send_message(
        relay,
        {:delete_appointment, appointment_id},
        region
      )

    {:ok, :irrelevant} =
      Relay.send_message(
        relay,
        {:query_by_patient, 0},
        region
      )
  end
end
