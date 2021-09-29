defmodule BinanceFuturesBot.TradeManager do
  require Logger

  use Supervisor

  alias BinanceFuturesBot.TradeManager
  alias BinanceFuturesBot.TradeManager.{StateHistory, TradeServer}

  def start_link(opts \\ []) do
    if is_nil(opts[:name]), do: raise "must set name in options for BinanceFuturesBot.TradeManager"
    if is_nil(opts[:symbol]), do: raise "must set symbol in options for BinanceFuturesBot.TradeManager"

    Supervisor.start_link(TradeManager, opts, Keyword.update!(opts, :name, &server_name/1))
  end

  def init(opts) do
    name = opts[:name]
    symbol = opts[:symbol]

    children = [
      {TradeServer, name: name, symbol: symbol},
      {StateHistory, name: name}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def server_name(name), do: :"trade_manager_#{name}_supervisor"

  def child_spec(opts), do: %{id: opts[:name], start: {TradeManager, :start_link, [opts]}}

  def get_current_state(name) do
    TradeServer.get_state(name)
  end

  def create_reversal_short(name) do
    open_and_monitor_trade(name, &TradeServer.create_reversal_short/1, "REVERSAL_SHORT")
  end

  def create_reversal_long(name) do
    open_and_monitor_trade(name, &TradeServer.create_reversal_long/1, "REVERSAL_LONG")
  end

  defp open_and_monitor_trade(name, trade_manager_fnc, history_type) do
    Logger.info("Creating #{history_type}...")

    case trade_manager_fnc.(name) do
      {:ok, {:trade_in_progress, _state}} = res ->
        Logger.info("Trade currently in progress, aborting...")

        res

      {:ok, %TradeServer.State{trade_in_progress?: false}} = res ->
        Logger.warn("Couldn't start trade for #{name}")

        res

      {:ok, state} = res ->
        Logger.info("Started trade for #{name}")

        StateHistory.log_history(name, "#{history_type}_OPENED", state)

        res

      e -> e
    end
  end
end
