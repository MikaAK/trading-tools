defmodule BinanceFuturesBot.TradeManager.TradeMonitor do
  use GenServer

  alias BinanceFuturesBot.TradeManager.TradeMonitor

  defmodule State do
    defstruct [
      :active?,
      :current_state,
      :interval_ref,
      recheck_interval: :timer.seconds(1)
    ]
  end

  def start_link(opts \\ []) do
    opts = Keyword.update!(opts, :name, &server_name/1)

    GenServer.start_link(TradeMonitor, nil, opts)
  end

  def init(_) do
    {:ok, %State{}}
  end

  def child_spec(opts) do
    %{
      id: server_name(opts[:name]),
      start: {TradeMonitor, :start_link, [opts]}
    }
  end

  def server_name(name), do: :"trade_manager_monitor_#{name}"

  def active?(name) do
    GenServer.call(server_name(name), :active?)
  end

  def activate(name, trade_server_state) do
    GenServer.cast(server_name(name), {:activate, trade_server_state})
  end

  def checkup_on_trade(name, trade_server_state) do
    GenServer.cast(server_name(name), {:checkup_on_trade, trade_server_state})
  end

  def handle_call(:active, _, state) do
    {:reply, state.active?, state}
  end

  def handle_cast({:activate, trade_server_state}, state) do
    interval_ref = :timer.send_interval(state.recheck_interval, self(), :checkup_on_trade)

    {:noreply, %{state |
      current_state: trade_server_state,
      interval_ref: interval_ref,
      active?: true
    }}
  end

  def handle_info(:checkup_on_trade, state) do

  end
end
