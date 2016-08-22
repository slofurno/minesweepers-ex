defmodule Minesweepers.Game.Square do
  alias Minesweepers.Game.Square
  @types [:empty, :bomb, :flag]

  defstruct [
    type: :empty,
    revealed: false,
    flagged: false,
    neighbors: 0,
    row: -1,
    col: -1
  ]

  def new(type, row, col) when type in @types do
    %Square{type: type}
  end

  def new(_type) do
    {:error, "bad type"}
  end
end
