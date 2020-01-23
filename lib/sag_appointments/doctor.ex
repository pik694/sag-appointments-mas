defmodule SagAppointments.Doctor do
  use GenServer

  @default_working_hours Enum.map(1..5, fn weekday -> {weekday, %{start: 9, end: 17}} end)
                         |> Map.new()

  defstruct [:name, :surname, :clinic, :working_hours, :visit_time]

  def init(opts) do
    default_values = [working_hours: @default_working_hours, visit_time: 15]
    state = struct!(__MODULE__, Keyword.merge(default_values, opts))
    {:ok, state}
  end
end
