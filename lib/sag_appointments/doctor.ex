defmodule SagAppointments.Doctor do
  require Logger
  use GenServer

  alias SagAppointments.Counters
  alias SagAppointments.Doctor.Schedule
  alias SagAppointments.Doctor.Core

  @default_working_hours Enum.map(1..5, fn weekday -> {weekday, %{start: 9, end: 17}} end)
                         |> Map.new()

  defstruct [
    :id,
    :name,
    :field,
    :working_hours,
    :visit_time,
    :forward_slots,
    :schedule
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    default_values = [
      working_hours: @default_working_hours,
      visit_time: 15,
      forward_slots: Timex.Duration.from_weeks(4)
    ]

    state = struct!(__MODULE__, Keyword.merge(default_values, opts))
    {:ok, state}
  end

  def handle_cast({{query_id, from}, {:query_available, opts}}, state) do
    if compare_name_and_field(state, opts) do
      Logger.info("Listing available slots")

      {:ok, future_appointments} = Schedule.get_future_appointments(state.schedule)
      available_slots = Core.available_slots(state, future_appointments, Timex.now(), opts)
      GenServer.cast(from, {:reply, query_id, {state.id, state.name, available_slots}})
    else
      GenServer.cast(from, {:reply, query_id, :irrelevant})
    end

    {:noreply, state}
  end

  def handle_cast({{query_id, from}, {:query_by_patient, patient_id}}, state) do
    Logger.info("Querying appointments of patient: #{patient_id}")

    {:ok, history} = Schedule.get_history(state.schedule)
    {:ok, future} = Schedule.get_future_appointments(state.schedule)

    case Core.get_appointments_for_patient(history, future, patient_id) do
      [] ->
        GenServer.cast(from, {:reply, query_id, :irrelevant})

      relevant ->
        GenServer.cast(from, {:reply, query_id, {state.id, state.name, state.field, relevant}})
    end

    {:noreply, state}
  end

  def handle_cast({{query_id, from}, {:add_appointment, doctor_id, patient_id, slot}}, state) do
    if doctor_id == state.id do
      Logger.info("Trying to add an appointment")

      {:ok, taken} = Schedule.get_future_appointments(state.schedule)
      appointment_id = Counters.appointment_id

      case Core.try_create_appointment(
             state,
             taken,
             Timex.now(),
             slot,
             patient_id,
             appointment_id
           ) do
        {:ok, appointment} ->
          Logger.info("Successfully created appointment #{appointment.id}")
          Schedule.add_appointment(state.schedule, appointment)
          GenServer.cast(from, {:reply, query_id, {:ok, appointment.id}})

        error ->
          Logger.warn("Could not create an appointment. Reason: #{error}")
          GenServer.cast(from, {:reply, query_id, error})
      end
    end

    {:noreply, state}
  end

  def handle_cast({{_query_id, _from}, {:delete_appointment, appointment_id}}, state) do
    Logger.info("Deleting appointment #{appointment_id}")
    Schedule.delete_appointment(state.schedule, appointment_id)
    {:noreply, state}
  end

  defp compare_name_and_field(state, opts) do
    Keyword.get(opts, :name, state.name) == state.name &&
      Keyword.get(opts, :field, state.field) == state.field
  end
end
