defmodule Minesweepers.Game.Board do
  alias Minesweepers.Game.Board
  alias Minesweepers.Game.Square
  alias Minesweepers.Rand

  defstruct [
    rows: 0,
    cols: 0,
    squares: %{}
  ]

  def new(rows, cols, chance) do
    squares = for row <- 0..rows-1,
      col <- 0..cols-1,
      into: %{},
      do: {{row, col}, make_square(chance)}

    board = %Board{squares: squares, rows: rows, cols: cols}

    squares = for row <- 0..rows-1,
      col <- 0..cols-1,
      into: %{},
      do: {{row, col}, with_neighbors(board, {row, col})}

    %Board{squares: squares, rows: rows, cols: cols}
  end

  def flag_square(%Board{} = board, {row, col} = pos) do

  end

  defp make_square(bomb_chance) do
    if bomb_chance > Rand.next(), do: Square.new(:bomb), else: Square.new(:empty)
  end

  defp with_neighbors(%Board{squares: squares, rows: rows, cols: cols} = board, {row, col} = pos) do
    bombs = for r <- row-1..row+1,
      c <- col-1..col+1,
      r != 0 || c != 0,
      r >= 0,
      c >= 0,
      r < rows,
      c < cols,
      isBomb(board, pos),
      do: {r, c}

    %Square{squares[pos]| neighbors: Enum.count(bombs) }
  end

  defp isBomb(board, {_row, _col} = pos) do
    %Square{type: type} = get_square(board, pos)
    type == :bomb
  end

  def get_square(%Board{squares: squares} = board, {row, col} = pos) do
    squares[pos]
  end

  defp check(%Board{rows: rows, cols: cols}, {row, col}) when row < rows and col < cols and row >= 0 and col >= 0 do
    :ok
  end

  defp check do
    0
  end

end
