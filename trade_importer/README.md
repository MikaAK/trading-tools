# TradeImporter
Parsing daily reports from Interactive Brokers to start building data

#### Goals
- [x] Be able to parse a csv and sort it by trades
- [x] Organize trades into completed and opened
- [ ] Add statistics around Trades Opened, Daily P&L and Win Rate
- [ ] Identify and group combo trades (spreads)
- [ ] Add Agent & Task to monitor and aggregate the daily usage / fill blanks
- [ ] Calculate days of week where I have the worst trades
- [ ] Calculate win percentage per ticker
- [ ] Calculate win percentage per bearish/bullish

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `trade_importer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:trade_importer, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/trade_importer](https://hexdocs.pm/trade_importer).

