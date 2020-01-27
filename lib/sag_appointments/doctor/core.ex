defmodule SagAppointments.Doctor.Core do
  alias Timex.Interval
  alias Timex.Duration

  alias SagAppointments.{Doctor, Appointment}

  def get_appointments_for_patient(historical, future, patient_id) do
    historical
    |> :erlang.++(future)
    |> Enum.filter(fn %Appointment{patient: id} -> id == patient_id end)
  end

  def try_create_appointment(state, taken, now, slot, patient_id, appointment_id) do
    available_slots = available_slots(state, taken, now, day: Timex.to_date(slot))

    if Enum.member?(available_slots, slot) do
      {:ok, %Appointment{id: appointment_id, slot: slot, patient: patient_id}}
    else
      :error
    end
  end

  def available_slots(state, taken, now, opts) do
    today = Timex.to_date(now)
    taken = Enum.map(taken, fn %{slot: slot} -> slot end)

    {begin_date, end_date} =
      case Keyword.fetch(opts, :day) do
        {:ok, day} -> {day, day}
        :error -> {Keyword.fetch!(opts, :from), Keyword.fetch!(opts, :until)}
      end

    valid_period_end = Timex.shift(today, duration: state.forward_slots) |> Timex.shift(days: -1)
    begin_date = if Timex.compare(today, begin_date) > 0, do: today, else: begin_date

    end_date =
      if Timex.compare(valid_period_end, end_date) < 0, do: valid_period_end, else: end_date

    query_end_time = Timex.to_naive_datetime(end_date) |> Timex.shift(hours: 23, minutes: 59)

    if Timex.compare(begin_date, end_date) < 1 do
      Interval.new(from: begin_date, until: query_end_time)
      |> Enum.map(&day_intervals(state.working_hours, state.visit_time, &1))
      |> Enum.map(&Enum.to_list/1)
      |> List.flatten()
      |> Enum.filter(fn slot -> Timex.compare(slot, now) > 0 end)
      |> :erlang.--(taken)
    else
      []
    end
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
