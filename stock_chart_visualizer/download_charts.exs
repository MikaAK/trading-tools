stock_url = fn symbol -> "http://localhost:4000/#{symbol}/2020/07/10" end


Application.put_env(:hound, :driver, "chrome_driver")
Application.put_env(:hound, :browser, "chrome_headless")

Mix.install([:hound])

Application.ensure_all_started(:hound)

alias Hound.Helpers.{Navigation, Session}

session_id = Hound.start_session(browser: "chrome_headless")

Process.sleep(10000)
Session.change_session_to(session_id)
Navigation.navigate_to(stock_url.("SPY"))

Process.sleep(10000)
