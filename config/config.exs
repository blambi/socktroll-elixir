use Mix.Config

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:module]

config :socktroll,
  port: 6000
