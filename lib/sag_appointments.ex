defmodule SagAppointments do
  alias SagAppointments.Router

  def get_available_slots(opts \\ []) do
    {:ok, response} = Router.get_available_slots(opts)
    handle_response(response)
  end

  def get_visits_for_user(id) do
    {:ok, response} = Router.get_visits_for_user(id)
    handle_response(response)
  end

  def delete_visit(visit_id) do
    {:ok, :irrelevant} = Router.delete_vist(visit_id)
    {:ok, :request_confirmed}
  end

  def add_visit(user_id, doctor_id, slot) do
    {:ok, response} = Router.add_visit(user_id, doctor_id, slot)

    case handle_response(response) do
      {:ok, [response]} -> response
      error -> error
    end
  end

  defp handle_response(:irrelevant), do: {:error, :could_not_succeed}

  defp handle_response(response) do
    results = Enum.map(response, &map_response_from_region/1) |> List.flatten()
    {:ok, results}
  end

  defp map_response_from_region(%{region: region, responses: responses}) do
    Enum.map(responses, &map_response_from_clinic(region, &1))
  end

  defp map_response_from_clinic(region, %{clinic: clinic, responses: responses}) do
    Enum.map(responses, &map_response_from_doctor(region, clinic, &1))
  end

  defp map_response_from_doctor(region, clinic, response) when is_map(response) do
    response |> Map.put_new(:region, region) |> Map.put_new(:clinic, clinic)
  end

  defp map_response_from_doctor(_region, _clinic, response) when is_tuple(response), do: response
end
