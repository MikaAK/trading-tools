defmodule TradeImporter.Entry do
  alias TradeImporter.Row

  @enforce_keys [
    :symbol,
    :entry_times,
    :exit_times,
    :positions_bought,
    :positions_sold,
    :entry_price,
    :current_price,
    :realized_change,
    :unrealized_change_percentage,
    :commission_paid
  ]
  defstruct @enforce_keys

  def deserialize_opened_trade(opened_trade) do
    %TradeImporter.Entry{
      symbol: Row.trade_symbol(opened_trade),
      entry_times: [Row.trade_time(opened_trade)],
      exit_times: nil,
      entry_price: Row.trade_purchased_price(opened_trade),
      current_price: Row.trade_current_price(opened_trade),
      positions_bought: Row.trade_position(opened_trade),
      positions_sold: 0,
      realized_change: Decimal.new(0),
      unrealized_change_percentage: Row.unrealized_change_percentage(opened_trade),
      commission_paid: Row.trade_commission(opened_trade)
    }
  end

  def deserialize_completed_trade(%{start: :unknown, end: ended_trade}) do
    %TradeImporter.Entry{
      symbol: Row.trade_symbol(ended_trade),
      entry_times: :unknown,
      exit_times: Row.trade_time(ended_trade),
      entry_price: Row.trade_purchased_price(ended_trade),
      current_price: Row.trade_current_price(ended_trade),
      positions_bought: :unknown,
      positions_sold: ended_trade |> Row.trade_position() |> abs,
      realized_change: Row.realized_profit(ended_trade),
      unrealized_change_percentage: Decimal.new(0),
      commission_paid: Row.trade_commission(ended_trade)
    }
  end

  def deserialize_completed_trade(%{start: starting_trades, end: ended_trade}) do
    %TradeImporter.Entry{
      symbol: Row.trade_symbol(ended_trade),
      entry_times: Enum.map(starting_trades, &Row.trade_time/1),
      exit_times: Row.trade_time(ended_trade),
      entry_price: avg_entry(starting_trades),
      current_price: Row.trade_current_price(ended_trade),
      positions_bought: Enum.reduce(starting_trades, 0, &(Row.trade_position(&1) + &2)),
      positions_sold: ended_trade |> Row.trade_position() |> abs,
      realized_change: Row.realized_profit(ended_trade),
      unrealized_change_percentage: 0,
      commission_paid: total_commission(starting_trades, ended_trade)
    }
  end

  defp avg_entry(starting_trades) do
    starting_trades
      |> Enum.reduce(0, fn trade, acc ->
        trade
          |> Row.trade_purchased_price
          |> Decimal.add(acc)
      end)
      |> Decimal.div(length(starting_trades))
  end

  defp total_commission(starting_trades, ended_trade) do
    Enum.reduce([ended_trade | starting_trades], 0, fn trade, acc ->
      trade
        |> Row.trade_commission()
        |> Decimal.add(acc)
    end)
  end
end
