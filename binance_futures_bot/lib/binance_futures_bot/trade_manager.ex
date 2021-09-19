defmodule BinanceFuturesBot.TradeManager do
  require Logger

  use Supervisor

  alias BinanceFuturesBot.TradeManager
  alias BinanceFuturesBot.TradeManager.{StateHistory, TradeMonitor, Server}

  def start_link(opts \\ []) do
    if is_nil(opts[:name]), do: raise "must set name in options for BinanceFuturesBot.TradeManager"

    Supervisor.start_link(TradeManager, opts[:name], opts)
  end

  def init(name) do
    children = [
      {Server, name: name},
      {TradeMonitor, name: name},
      {StateHistory, name: name}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def child_spec(opts), do: Supervisor.child_spec(opts, id: opts[:name])

  def create_reversal_short(name) do
    open_and_monitor_trade(name, &Server.create_reversal_short/1, "REVERSAL_SHORT")
  end

  def create_reversal_long(name) do
    open_and_monitor_trade(name, &Server.create_reversal_long/1, "REVERSAL_LONG")
  end

  defp open_and_monitor_trade(name, trade_manager_fnc, history_type) do
    Logger.info("Creating #{history_type}...")

    case name |> Server.server_name |> trade_manager_fnc.() do
      {:ok, {:trade_in_progress, state}} = res ->
        Logger.info("Trade currently in progress, aborting...")

        maybe_monitor_trade(name, state)

        res

      {:ok, state} = res ->
        Logger.info("Started trade:\n#{inspect state}")

        log_state_history(name, "#{history_type}_OPENED", state)

        monitor_trade(name, state)

        res

      e -> e
    end
  end

  defp log_state_history(name, type, state) do
    name
      |> StateHistory.server_name
      |> StateHistory.log_history(type, state)
  end

  defp maybe_monitor_trade(name, state) do
    server_name = TradeMonitor.server_name(name)

    if not TradeMonitor.active?(server_name) do
      TradeMonitor.activate(server_name, state)
    end
  end

  defp monitor_trade(name, state) do
    name |> TradeMonitor.server_name |> TradeMonitor.activate(state)
  end
end
