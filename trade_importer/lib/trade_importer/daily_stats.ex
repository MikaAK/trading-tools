defmodule TradeImporter.DailyStats do
  defstruct [
    wins: 0,
    win_rate: 0,
    total_trades: 0,
    total_commissions: Decimal.new(0),
    realized_change: Decimal.new(0)
  ]

  def calculate(trade_entries) do
    trade_entries
    |> group_by_date
    |> Enum.into(%{}, fn
      {nil, trades} -> {:unclosed_or_expired, trades}
      {date, trades} -> {date, calculate_daily_stats(trades)}
    end)
  end

  defp group_by_date(trade_entries) do
    Enum.group_by(trade_entries, fn
      %TradeImporter.Entry{exit_times: nil} -> nil
      %TradeImporter.Entry{exit_times: exit_times} -> NaiveDateTime.to_date(exit_times)
    end)
  end

  defp calculate_daily_stats(daily_trade_entries) do
    daily_trade_entries
      |> compress_trades_opened_at_the_same_time
      |> Enum.reduce(%TradeImporter.DailyStats{}, fn (%TradeImporter.Entry{} = trade_entry, acc) ->
        %{acc |
          wins: acc.wins + trade_win_int(trade_entry),
          total_trades: acc.total_trades + 1,
          realized_change: Decimal.add(acc.realized_change, trade_entry.realized_change)
        }
      end)
      |> calculate_win_rate
  end

  defp compress_trades_opened_at_the_same_time(daily_trade_entries) do
    {multiple_symbol_trades, non_multiple_trades} = daily_trade_entries
      |> Enum.group_by(fn
        %TradeImporter.Entry{symbol: symbol, entry_times: [entry_time|_]} -> {symbol, entry_time}
        %TradeImporter.Entry{symbol: _, entry_times: :unknown} -> :unknown
      end)
      |> Enum.split_with(fn {symbol, entries} -> symbol !== :unknown and length(entries) > 1 end)

    multiple_symbol_trades
      |> compress_open_trades
      |> Kernel.++(Enum.flat_map(non_multiple_trades, &elem(&1, 1)))
  end

  defp compress_open_trades(multiple_symbol_trades) do
    Enum.map(multiple_symbol_trades, fn {_symbol_open_time_tuple, trades} ->
      first_trade = trades |> hd() |> Map.update!(:exit_times, &[&1])

      trades
        |> tl
        |> Enum.reduce(first_trade, fn (trade, acc_trade) ->
          %{acc_trade |
            realized_change: Decimal.add(acc_trade.realized_change, trade.realized_change),
            commission_paid: Decimal.add(acc_trade.commission_paid, trade.commission_paid),
            exit_times: [trade.exit_times | acc_trade.exit_times],
            positions_bought: acc_trade.positions_bought + trade.positions_bought,
            positions_sold: acc_trade.positions_sold + trade.positions_sold
          }
        end)
        |> Map.update!(:exit_times, &Enum.reverse/1)
    end)
  end

  defp trade_win_int(%TradeImporter.Entry{realized_change: realized_change}) do
    if Decimal.positive?(realized_change), do: 1, else: 0
  end

  defp calculate_win_rate(%TradeImporter.DailyStats{
    wins: wins,
    total_trades: total_trades
  } = stats_for_day) do
    Map.put(stats_for_day, :win_rate, wins / total_trades)
  end
end
