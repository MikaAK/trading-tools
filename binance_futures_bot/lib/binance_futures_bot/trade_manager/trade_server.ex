defmodule BinanceFuturesBot.TradeManager.TradeServer do
  use GenServer

  alias BinanceFuturesBot.TradeManager.{TradeServer, StateHistory}
  alias BinanceFuturesBot.TradeManager.TradeServer.{State, ReversalLong, ReversalShort, BinanceConnector}

  @check_interval :timer.seconds(1)

  def start_link(opts \\ []) do
    GenServer.start_link(TradeServer, opts, Keyword.update!(opts, :name, &server_name/1))
  end

  def init(opts) do
    {:ok, %{}, {:continue, opts}}
  end

  def child_spec(opts) do
    %{
      id: opts[:name],
      start: {TradeServer, :start_link, [opts]}
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

  def handle_continue(opts, _) do
    {name, opts} = Keyword.pop(opts, :name)
    {symbol, opts} = Keyword.pop(opts, :symbol)

    state = BinanceConnector.seed_from_api(name, symbol, opts)

    :timer.send_interval(@check_interval, :checkup_on_trade)

    {:noreply, state}
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

  def handle_info(:checkup_on_trade, %State{} = state) do
    new_state = BinanceConnector.checkup_on_trade(state)

    case new_state do
      ^state -> {:noreply, state}

      %State{trade_in_progress?: false} ->
        StateHistory.log_history(state.name, "TRADE_ENDED", state)

      %State{taken_first_avg?: true} when not state.taken_first_avg? ->
        StateHistory.log_history(state.name, "FIRST_AVG_TAKEN", state)

      %State{taken_second_avg?: true} when not state.taken_second_avg? ->
        StateHistory.log_history(state.name, "SECOND_AVG_TAKEN", state)

      %State{order_position: %State.OrderPosition{take_profit_order: %{"status" => "FILLED"}}} ->
        StateHistory.log_history(state.name, "PROFIT_TAKEN", state)

      %State{order_position: %State.OrderPosition{stop_order: %{"status" => "FILLED"}}} ->
        StateHistory.log_history(state.name, "STOPPED_OUT", state)
    end

    {:noreply, new_state}
  end
end
