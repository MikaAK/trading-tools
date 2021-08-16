# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Configures the endpoint
config :stock_chart_visualizer, StockChartVisualizerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "dY+Pa3DGVfPhGI1b9PeCQqEYKV8htVoE/tAo/C/3CnCswrz+1gihCbo6/kpV5poB",
  render_errors: [view: StockChartVisualizerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: StockChartVisualizer.PubSub,
  live_view: [signing_salt: "EMJvCLHh"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
