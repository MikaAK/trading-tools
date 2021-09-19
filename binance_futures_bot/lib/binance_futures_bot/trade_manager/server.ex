defmodule BinanceFuturesBot.TradeManager.Server do
  use GenServer

  alias BinanceFuturesBot.TradeManager.{Server, StateHistory}
  alias BinanceFuturesBot.TradeManager.Server.{State, ReversalLong, ReversalShort}

  def start_link(opts \\ []) do
    opts = Keyword.update!(opts, :name, &server_name/1)

    GenServer.start_link(Server, opts, opts)
  end

  def init(opts) do
    State.seed_from_binance(opts[:symbol], Map.delete(opts, :name))
  end

  def child_spec(opts) do
    %{
      id: server_name(opts[:name]),
      start: {Server, :start_link, [opts]}
    }
  end

  def server_name(name), do: :"trade_manager_server_#{name}"

  def create_reversal_short(server) do
    GenServer.call(server, :reversal_short)
  end

  def create_reversal_long(server) do
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
