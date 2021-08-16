defmodule TradeImporter.Row do
  def update_trade_position(row, position), do: put_in(row, [Access.at(8)], position)
  def trade_position(row), do: row |> Enum.at(8) |> maybe_parse_int
  def realized_profit(row), do: row |> Enum.at(14) |> maybe_parse_decimal
  def trade_time(row), do: Enum.at(row, 6)
  def record_type(row), do: Enum.at(row, 0)
  def order_type(row), do: Enum.at(row, 2)
  def trade_asset(row), do: Enum.at(row, 3)
  def trade_commission(row), do: row |> Enum.at(12) |> maybe_parse_decimal
  def trade_symbol(row), do: Enum.at(row, 5)
  def trade_current_price(row), do: row |> Enum.at(10) |> maybe_parse_decimal
  def trade_purchased_price(row), do: row |> Enum.at(9) |> maybe_parse_decimal

  def maybe_parse_int(str) when is_binary(str), do: str |> Integer.parse |> elem(0)
  def maybe_parse_int(int), do: int

  def maybe_parse_decimal(str) when is_binary(str), do: Decimal.new(str)
  def maybe_parse_decimal(decimal), do: decimal

  def unrealized_change_percentage(row) do
    row
      |> trade_current_price
      |> Decimal.div(trade_purchased_price(row))
      |> Decimal.add(-1)
      |> Decimal.mult(100)
  end
end
