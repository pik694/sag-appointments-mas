defmodule SagAppointments.TestFixtures do
  use ExUnitFixtures.FixtureModule

  alias SagAppointments.TestHelpers.Relay

  deffixture relay() do
    {:ok, relay} = Relay.start_link(100)
    relay
  end

  deffixture doctors_spec() do
    [
      [name: "John Smith", field: "Pediatrician"],
      [name: "Jack Smith", field: "Pediatrician"],
      [name: "John Smith", field: "Dentist"],
      [name: "Jack Jones", field: "Pediatrician", visit_time: 10]
    ]
  end
end
