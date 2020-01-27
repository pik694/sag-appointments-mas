defmodule SagAppointments.Application do
  use Application
  
  alias SagAppointments.Appointment

  def start(_type, _args) do

    :ok = Appointment.init() 

    children = []
    
    Supervisor.start_link(children, strategy: :one_for_one, name: SagAppointments.Supervisor)
  end
end
