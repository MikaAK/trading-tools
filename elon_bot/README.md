# ElonBot

SUPER SIMPLE Elon twitter bot, posts to a discord channel.

To config create a `config/config.secrets.exs` and inside put the following:

```elixir
import Config

config :elon_bot,
  discord_webhook_url: "<INSERT WEBHOOK>",
  twitter_bearer_token: "<INSERT TWITTER>"
```

You will then be able to run the bot which will start posting to discord
with the first post and then every new post that comes in
