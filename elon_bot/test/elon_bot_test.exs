defmodule ElonBotTest do
  use ExUnit.Case
  doctest ElonBot

  test "greets the world" do
    assert ElonBot.hello() == :world
  end
end
