defmodule SagAppointments.MixProject do
  use Mix.Project

  def project do
    [
      app: :sag_appointments,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixir_paths: elixir_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {SagAppointments.Application},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.4"},
      {:jason, "~> 1.1"},
      {:plug_cowboy, "~> 2.1"},
      {:ex_unit_fixtures, "~> 0.3", only: [:test]}
    ]
  end

  defp elixir_paths(:test), do: ["lib", "test/test_helpers"]
  defp elixir_paths(_), do: ["lib"]
  
end
