defmodule GYMTest do
  use ExUnit.Case
  doctest GYM

  test "greets the world" do
    assert GYM.hello() == :world
  end
end
