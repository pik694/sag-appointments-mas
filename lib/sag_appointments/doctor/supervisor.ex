defmodule SagAppointments.Doctor.Supervisor do
  use Supervisor

  alias SagAppointments.Doctor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    children = [
      %{id: :schedule, start: {Doctor.Schedule, :start_link, []}},
      %{id: :doctor, start: {Doctor, :start_link, [opts, self()]}}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  def child(supervisor, id) do
    maybe_child =
      supervisor
      |> Supervisor.which_children()
      |> Enum.find(fn
        {^id, pid, _, _} when is_pid(pid) -> true
        _ -> false
      end)

    case maybe_child do
      {_, pid, _, _} -> pid
      nil -> nil
    end
  end
end
