defmodule SagAppointments.Clinic.Supervisor do
  use Supervisor

  alias SagAppointments.Clinic
  alias SagAppointments.Doctor
  alias SagAppointments.Counters

  def start_link({clinic_name, doctors_opts}) do
    Supervisor.start_link(__MODULE__, {clinic_name, doctors_opts})
  end

  def init({clinic_name, doctors_opts}) do
    doctors =
      doctors_opts
      |> Enum.map(&Keyword.put_new(&1, :id, Counters.doctor_id()))
      |> Enum.map(fn opts ->
        %{
          id: Keyword.fetch!(opts, :id),
          start: {Doctor.Supervisor, :start_link, [opts]},
          type: :supervisor
        }
      end)

    clinic = %{id: :clinic, start: {Clinic, :start_link, [clinic_name, self()]}, type: :worker}
    Supervisor.init([clinic | doctors], strategy: :one_for_one)
  end

  def clinic(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.find(fn
      {:clinic, _, _, _} -> true
      _ -> false
    end)
    |> elem(1)
  end

  def doctors(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.filter(fn
      {id, _, _, _} when is_integer(id) -> true
      _ -> false
    end)
    |> Enum.map(fn {_, pid, _, _} -> Doctor.Supervisor.child(pid, :doctor) end)
    |> Enum.filter(&is_pid/1)
  end
end
