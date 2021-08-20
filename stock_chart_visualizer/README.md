# StockChartVisualizer

Used to generate stock pictures for a large period of time.


To use this first startup chromedriver

```bash
$ chromedriver  --headless --disable-gpu --disable-software-rasterizer
```

Then startup the server
```bash
$ iex -S mix phx.server
```

Finally run the `download_charts.exs` script

```bash
$ elixir ./download_charts.exs
```

### Modifications
To modify the stocks being captured you can go to the `download_charts.ex` and
set the `generation_symbols` list to include the symbols you wish to capture

One gotcha currently is that the `start_year` is fixed so it's currently impossible to run for multiple stocks at the same time if there is no start year overlap
