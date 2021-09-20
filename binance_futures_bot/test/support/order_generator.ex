defmodule BinanceFuturesBot.Support.OrderGenerator do
  def open_limit_order(side, quantity, price) do
    %{
      "avg_price" => "0",
      "client_order_id" => "android_niYTrYliEqPCD2UNtUNF",
      "close_position" => false,
      "cum_quote" => "0",
      "executed_qty" => "0",
      "order_id" => 31818651823,
      "orig_qty" => to_string(quantity),
      "orig_type" => "LIMIT",
      "position_side" => "BOTH",
      "price" => to_string(price),
      "price_protect" => false,
      "reduce_only" => false,
      "side" => side,
      "status" => "NEW",
      "stop_price" => "0",
      "symbol" => "BTCUSDT",
      "time" => DateTime.to_unix(DateTime.utc_now(), :millisecond),
      "time_in_force" => "GTC",
      "type" => "LIMIT",
      "update_time" => 1632113040336,
      "working_type" => "CONTRACT_PRICE"
    }
  end

  def open_stop_market_order(side, status, quantity, price) do
    %{
      "avg_price" => "0",
      "client_order_id" => "android_0zzhf7yTuSXsNqeI9qx0",
      "close_position" => false,
      "cum_quote" => "0",
      "executed_qty" => "0",
      "order_id" => 31814842366,
      "orig_qty" => to_string(quantity),
      "orig_type" => "STOP_MARKET",
      "position_side" => "BOTH",
      "price" => to_string(price),
      "price_protect" => true,
      "reduce_only" => true,
      "side" => side,
      "status" => status,
      "stop_price" => "45200",
      "symbol" => "BTCUSDT",
      "time" => DateTime.to_unix(DateTime.utc_now(), :millisecond),
      "time_in_force" => "GTE_GTC",
      "type" => "STOP_MARKET",
      "update_time" => 1632109118907,
      "working_type" => "MARK_PRICE"
    }
  end

  def open_take_profit_order(side, status, quantity, price) do
    %{
      "avg_price" => "0",
      "client_order_id" => "android_Xf8mQMpLZNoRnDfTl9XX",
      "close_position" => false,
      "cum_quote" => "0",
      "executed_qty" => "0",
      "order_id" => 31814828774,
      "orig_qty" => to_string(quantity),
      "orig_type" => "TAKE_PROFIT",
      "position_side" => "BOTH",
      "price" => to_string(price),
      "price_protect" => true,
      "reduce_only" => true,
      "side" => side,
      "status" => status,
      "stop_price" => "45800",
      "symbol" => "BTCUSDT",
      "time" => DateTime.to_unix(DateTime.utc_now(), :millisecond),
      "time_in_force" => "GTE_GTC",
      "type" => "TAKE_PROFIT",
      "update_time" => 1632109105313,
      "working_type" => "MARK_PRICE"
    }
  end

  def opened_position_order(side, status, quantity, price) do
    %{
      "avg_price" => to_string(price),
      "client_order_id" => "android_04yZuo9IGTlBXxF8RjQb",
      "close_position" => false,
      "cum_quote" => "365.82064",
      "executed_qty" => to_string(quantity),
      "order_id" => 31821084564,
      "orig_qty" => "0.008",
      "orig_type" => "LIMIT",
      "position_side" => "BOTH",
      "price" => to_string(price),
      "price_protect" => false,
      "reduce_only" => false,
      "side" => side,
      "status" => status,
      "stop_price" => "0",
      "symbol" => "BTCUSDT",
      "time" => DateTime.to_unix(DateTime.utc_now(), :millisecond),
      "time_in_force" => "GTC",
      "type" => "LIMIT",
      "update_time" => 1632116425287,
      "working_type" => "CONTRACT_PRICE"
    }
  end

  def closed_position_order(side, status, quantity, price) do
    %{
      "avg_price" => to_string(price),
      "client_order_id" => "android_XhryufZmu1wugQwfZGZm",
      "close_position" => false,
      "cum_quote" => "182.89472",
      "executed_qty" => to_string(quantity),
      "order_id" => 31821087140,
      "orig_qty" => to_string(quantity),
      "orig_type" => "MARKET",
      "position_side" => "BOTH",
      "price" => "0",
      "price_protect" => false,
      "reduce_only" => true,
      "side" => side,
      "status" => status,
      "stop_price" => "0",
      "symbol" => "BTCUSDT",
      "time" => DateTime.to_unix(DateTime.utc_now(), :millisecond),
      "time_in_force" => "GTC",
      "type" => "MARKET",
      "update_time" => 1632116430266,
      "working_type" => "CONTRACT_PRICE"
    }
  end
end
