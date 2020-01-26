defmodule SagAppointments.Doctor do
  require Logger
  use GenServer

  alias SagAppointments.Message
  alias SagAppointments.Doctor.Schedule
  alias SagAppointments.Doctor.Core

  @default_working_hours Enum.map(1..5, fn weekday -> {weekday, %{start: 9, end: 17}} end)
                         |> Map.new()

  defstruct [
    :name,
    :surname,
    :field,
    :clinic,
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

  def handle_cast(%Message{message: {:query, :slots}} = message, state) do
    Logger.info("Received free slots query")
    {begin_date, end_date} = message.content
    {:ok, taken_slots} = Schedule.get_taken_slots(state.schedule)
    available_slots = Core.available_slots(state, taken_slots, begin_date, end_date)

    GenServer.cast(message.from, %Message{
      message: {:reply, :slots},
      content: available_slots,
      from: self(),
      query: message
    })

    {:noreply, state}
  end

  def handle_call(%Message{message: :add_appointment} = message, _from, state) do
    Logger.info("Adding appointment:")
    {slot, patient} = message.content

    response =
      with {:ok, taken} <- Schedule.get_taken_slots(state.schedule),
           :ok <- Core.check_slot_available(state, taken, slot) do
        Schedule.add_appointment(state.schedule, %Schedule.Appointment{slot: slot, patient: patient})
        :ok
      end

    {:reply, response, state}
  end
end
