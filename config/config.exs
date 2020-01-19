use Mix.Config

config :logger,
       :console,
       format: "$time $metadata[$level]: $message\n",
       metadata: [:requiest_id]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
