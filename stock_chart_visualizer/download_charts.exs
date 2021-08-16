stock_url = fn
  symbol, <<year::byte-size(4), "-", month::byte-size(2), "-", day:byte-size(2)>> ->
    "http://localhost:4000/#{symbol}/#{year}/#{month}/#{day}"
end

generation_symbols = ["SPY"]
generation_dates = {Date.new(1995, 1, 1), Date.utc_today()}


Application.put_env(:hound, :driver, "chrome_driver")
Application.put_env(:hound, :browser, "chrome_headless")

Mix.install([:hound])

Application.ensure_all_started(:hound)

alias Hound.Helpers.{Navigation, Session}

session_id = Hound.start_session(browser: "chrome_headless")

Session.change_session_to(session_id)

Navigation.navigate_to(stock_url.("SPY"))



