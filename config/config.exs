use Mix.Config

config :logger,
       :console,
       format: "$time $metadata[$level]: $message\n",
       metadata: [:requiest_id]

config :logger,
  level: :warn

# config :phoenix, :json_library, Jason

config :sag_appointments,
  doctor_crash_threshold: 0

import_config "#{Mix.env()}.exs"
