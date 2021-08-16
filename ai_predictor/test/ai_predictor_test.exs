defmodule AiPredictorTest do
  use ExUnit.Case
  doctest AiPredictor

  test "greets the world" do
    assert AiPredictor.hello() == :world
  end
end
