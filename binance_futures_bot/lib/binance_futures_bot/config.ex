defmodule BinanceFuturesBot.Config do
  @app :binance_futures_bot

  def webhook_secret, do: get_key(:webhook_secret)

  defp get_key(key), do: Application.get_env(@app, key)
end
