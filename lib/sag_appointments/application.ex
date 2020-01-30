defmodule SagAppointments.Application do
  use Application

  alias SagAppointments.Counters

  def start(_type, _args) do
    :ok = Counters.init()

    router = %{id: :router, start: {SagAppointments.Router, :start_link, []}}

    Supervisor.start_link([router | children(Mix.env())],
      strategy: :one_for_one,
      name: SagAppointments.Supervisor
    )
  end

  #
  # defp children(:test) do
  # []
  # end
  #
  defp children(_) do
    [
      {"Warszawa",
       [
         {"Przychodnia 1",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 2",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 3",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 4",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 5",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]}
       ]},
      {"Pruszków",
       [
         {"Przychodnia 1",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 2",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 3",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 4",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 5",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]}
       ]},
      {"Grodzisk Mazowiecki",
       [
         {"Przychodnia 1",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 2",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 3",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 4",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 5",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]}
       ]},
      {"Piaseczno",
       [
         {"Przychodnia 1",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 2",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 3",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 4",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]},
         {"Przychodnia 5",
          [
            [name: "Jan Kowalski", field: "Okulista", visit_time: 30],
            [name: "Jan Nowak", field: "Pediatra"],
            [name: "Adam Kowalski", field: "Laryngolog", visit_time: 10],
            [name: "Adam Nowak", field: "Okulista"],
            [name: "Jan Kowalski", field: "Okulista", visit_time: 25]
          ]}
       ]}
    ]
    |> Enum.zip(1..10)
    |> Enum.map(fn {config, id} ->
      %{
        id: id,
        start: {SagAppointments.Region.Supervisor, :start_link, [config]},
        type: :supervisor
      }
    end)
  end
end
