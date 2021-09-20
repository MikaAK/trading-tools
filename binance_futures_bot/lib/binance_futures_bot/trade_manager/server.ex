defmodule BinanceFuturesBot.TradeManager.Server do
  use GenServer

  alias BinanceFuturesBot.TradeManager.Server
  alias BinanceFuturesBot.TradeManager.Server.{State, ReversalLong, ReversalShort}

  def start_link(opts \\ []) do
    GenServer.start_link(Server, opts, Keyword.update!(opts, :name, &server_name/1))
  end

  def init(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    {symbol, opts} = Keyword.pop(opts, :symbol)

    {:ok, State.seed_from_binance(name, symbol, opts)}
  end

  def child_spec(opts) do
    %{
      id: opts[:name],
      start: {Server, :start_link, [opts]}
    }
  end

  def server_name(name), do: :"trade_manager_server_#{name}"

  def create_reversal_short(server) do
    GenServer.call(server_name(server), :reversal_short)
  end

  def create_reversal_long(server) do
    GenServer.call(server_name(server), :reversal_long)
  end

  def get_state(server) do
    GenServer.call(server_name(server), :get_state)
  end

  def handle_call(:reversal_long, _, state) do
    {reply, state} = ReversalLong.run(state)

    {:reply, reply, state}
  end

  def handle_call(:reversal_short, _, state) do
    {reply, state} = ReversalShort.run(state)

    {:reply, reply, state}
  end

  def handle_call(:get_state, _, state) do
    {:reply, state, state}
  end
end
