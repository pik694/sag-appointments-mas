defmodule SagAppointments.Application do
  use Application

  alias SagAppointments.Counters

  def start(_type, _args) do
    :ok = Counters.init()

    children = []

    Supervisor.start_link(children, strategy: :one_for_one, name: SagAppointments.Supervisor)
  end
end
