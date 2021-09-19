defmodule BinanceFuturesBot.TradeManager do
  use GenServer

  alias BinanceFuturesBot.TradeManager.{State, ReversalLong, ReversalShort}

  @default_name :trade_manager

  def start_link(opts \\ []) do
    GenServer.start_link(BinanceFuturesBot.TradeManager, opts, opts)
  end

  def init(opts) do
    State.seed_from_binance(opts[:symbol], Map.delete(opts, :name))
  end

  def create_reversal_short(server \\ @default_name) do
    GenServer.call(server, :reversal_short)
  end

  def create_reversal_long(server \\ @default_name) do
    GenServer.call(server, :reversal_long)
  end

  def handle_cast(:reversal_long, state) do
    {reply, state} = ReversalLong.run(state)

    {:reply, reply, state}
  end

  def handle_cast(:reversal_short, state) do
    {reply, state} = ReversalShort.run(state)

    {:reply, reply, state}
  end
end
