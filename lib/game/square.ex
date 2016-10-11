defmodule Minesweepers.Game.Squarex do
  alias Minesweepers.Game.Squarex
  import Minesweepers.Records
  @types [:empty, :bomb]

  defstruct [
    type: :empty,
    revealed: false,
    flagged: false,
    neighbors: 0,
    row: -1,
    col: -1
  ]


  def new(type, row, col) when type in @types do
    square(type: type, neighbors: 0, row: row, col: col)
    #%Square{type: type, row: row, col: col}
  end

  def new(_type) do
    {:error, "bad type"}
  end

  def is_revealed(%Squarex{revealed: revealed}), do: revealed
end

