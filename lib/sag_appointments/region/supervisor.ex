defmodule SagAppointments.Region.Supervisor do
  use Supervisor

  alias SagAppointments.Region
  alias SagAppointments.Clinic
  alias SagAppointments.Counters

  def start_link({region_name, clinics_opts}) do
    Supervisor.start_link(__MODULE__, {region_name, clinics_opts})
  end

  def init({region_name, clinics_opts}) do
    clinics =
      clinics_opts
      |> Enum.map(fn args ->
        %{
          id: Counters.clinic_id(),
          start: {Clinic.Supervisor, :start_link, [args]},
          type: :supervisor
        }
      end)

    region = %{id: :region, start: {Region, :start_link, [region_name, self()]}, type: :worker}
    Supervisor.init([region | clinics], strategy: :one_for_one)
  end

  def clinics(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.filter(fn
      {id, _, _, _} when is_integer(id) -> true
      _ -> false
    end)
    |> Enum.map(fn {_, pid, _, _} -> Clinic.Supervisor.clinic(pid) end)
    |> Enum.filter(&is_pid/1)
  end
end
