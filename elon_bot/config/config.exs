import Config

config :elon_bot, :twitter_bearer_token, ""
config :elon_bot, :discord_webhook_urls, [""]

import_config "./config.secrets.exs"
