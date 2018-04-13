defmodule DwarfTest do
  use ExUnit.Case
  doctest Dwarf

  test "greets the world" do
    assert Dwarf.hello() == :world
  end
end
