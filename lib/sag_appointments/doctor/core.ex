defmodule SagAppointments.Doctor.Core do
  alias Timex.Interval
  alias Timex.Duration

  alias SagAppointments.Doctor

  def slots(%Doctor{} = state, begin_date), do: slots(state, begin_date, begin_date)

  def slots(%Doctor{working_hours: working_hours, visit_time: visit_time}, begin_date, end_date) do
    query_end_time = Timex.to_naive_datetime(end_date) |> Timex.shift(hours: 23, minutes: 59)

    Interval.new(from: begin_date, until: query_end_time)
    |> Enum.map(&day_intervals(working_hours, visit_time, &1))
    |> Enum.map(&Enum.to_list/1)
    |> List.flatten()
  end

  def available_slots(%Doctor{} = state, taken, begin_date),
    do: available_slots(state, taken, begin_date, begin_date)

  def available_slots(%Doctor{} = state, taken, begin_date, end_date) do
    slots(state, begin_date, end_date) -- taken
  end

  
  def check_slot_available(state, taken, slot) do
    :ok 
  end
  
  defp day_intervals(working_hours, visit_time, date) do
    with {:ok, %{start: day_start, end: day_end}} <-
           Map.fetch(working_hours, Timex.weekday(date)),
         from <- Timex.add(date, Duration.from_hours(day_start)),
         until <- Timex.add(date, Duration.from_hours(day_end)) do
      Interval.new(from: from, until: until, step: [minutes: visit_time])
    else
      _ -> []
    end
  end
end
