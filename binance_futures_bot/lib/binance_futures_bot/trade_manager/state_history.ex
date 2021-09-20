defmodule BinanceFuturesBot.TradeManager.StateHistory do
  use Agent

  def start_link(opts \\ []) do
    Agent.start_link(
      fn -> %{name: opts[:name], history: []} end,
      Keyword.update!(opts, :name, &server_name/1)
    )
  end

  def child_spec(opts) do
    %{
      id: server_name(opts[:name]),
      start: {BinanceFuturesBot.TradeManager.StateHistory, :start_link, [opts]}
    }
  end

  def server_name(name), do: :"trade_manager_state_history_#{name}"

  def log_history(name, type, new_state) do
    Agent.update(server_name(name), fn %{history: history} = state ->
      %{state | history: [%{type: type, state: new_state} | history]}
    end)
  end

  def get_history(name), do: Agent.get(server_name(name), &Map.get(&1, :history))
end
