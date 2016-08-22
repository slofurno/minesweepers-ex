defmodule Minesweepers.Game.Square do
  alias Minesweepers.Game.Square
  @types [:empty, :bomb, :flag, :revealed, :exploded]

  defstruct [
    type: :empty,
    neighbors: 0
  ]

  def new(type) when type in @types do
    %Square{type: type}
  end

  def new(_type) do
    {:error, "bad type"}
  end
end
