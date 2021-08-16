defmodule ElonBot.Config do
  def twitter_bearer_token, do: Application.get_env(:elon_bot, :twitter_bearer_token)
  def discord_webhook_urls, do: Application.get_env(:elon_bot, :discord_webhook_urls)
end
