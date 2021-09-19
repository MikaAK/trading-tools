defmodule BinanceFuturesBotWeb.Support.DateTimeHelpers do
  def within_second?(date_a, date_b) do
    date_a
      |> DateTime.diff(date_b)
      |> abs
      |> Kernel.<(2)
  end
end
