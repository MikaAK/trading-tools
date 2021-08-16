defmodule TradeImporter.TradeCompleter do
  alias TradeImporter.Row

  def organize_trades_into_completed(data) do
    Enum.map(data, fn {order_strike_exp, trades} ->
      trades = Enum.sort_by(trades, &Row.trade_time/1, :asc)
      {completed, opened} = split_completed_and_opened_trades(trades)

      {order_strike_exp, %{
        completed: Enum.reverse(completed),
        opened: Enum.reverse(opened)
      }}
    end)
  end

  defp split_completed_and_opened_trades(trades) do
    Enum.reduce(trades, {[], []}, fn trade, {completed, opened} ->
      trade = Row.update_trade_position(trade, Row.trade_position(trade))
      position = Row.trade_position(trade)

      cond do
        position === 0 -> {completed, opened}
        Row.realized_profit(trade) === Decimal.new(0) -> {completed, [trade | opened]}
        position < 0 -> complete_long_trade(trade, completed, opened)
        position > 0 -> complete_short_trade(trade, completed, opened)
      end
    end)
  end

  defp complete_long_trade(trade, completed, []) do
    {[%{start: :unknown, end: trade} | completed], []}
  end

  defp complete_long_trade(trade, completed, opened) do
    {completed_trade, new_opened} = opened
      |> Enum.reverse
      |> Enum.reduce_while({%{end: trade}, opened}, fn (opened_trade, {acc_trade, acc_opened}) ->
        opened_position = Row.trade_position(opened_trade)
        trade_position = Row.trade_position(trade)
        position_delta = opened_position + trade_position
        completed_trade = Map.update(acc_trade, :start, [opened_trade], &[opened_trade | &1])

        cond do
          position_delta === 0 ->
            {:halt, {completed_trade, tl(acc_opened)}}

          position_delta > 0 ->
            opened_trade = Row.update_trade_position(opened_trade, position_delta)

            {:halt, {completed_trade, [opened_trade | tl(acc_opened)]}}

          position_delta < 0 ->
            {:cont, {completed_trade, tl(acc_opened)}}
        end
      end)

    {
      [update_in(completed_trade.start, &Enum.reverse/1) | completed],
      Enum.reverse(new_opened)
    }
  end

  defp complete_short_trade(trade, completed, []) do
    {[%{start: :unknown, end: trade} | completed], []}
  end

  defp complete_short_trade(trade, completed, opened) do
    {completed_trade, new_opened} = opened
      |> Enum.reverse
      |> Enum.reduce_while({%{end: trade}, opened}, fn (opened_trade, {acc_trade, acc_opened}) ->
        opened_position = Row.trade_position(opened_trade)
        trade_position = Row.trade_position(trade)
        position_delta = opened_position + trade_position
        completed_trade = Map.update(acc_trade, :start, [opened_trade], &[opened_trade | &1])

        cond do
          position_delta === 0 ->
            {:halt, {completed_trade, tl(acc_opened)}}

          position_delta < 0 ->
            opened_trade = Row.update_trade_position(opened_trade, position_delta)

            {:halt, {completed_trade, [opened_trade | tl(acc_opened)]}}

          position_delta > 0 ->
            {:cont, {completed_trade, tl(acc_opened)}}
        end
      end)

    {
      [update_in(completed_trade.start, &Enum.reverse/1) | completed],
      Enum.reverse(new_opened)
    }
  end
end
