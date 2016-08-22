defmodule MinesweepersTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias Minesweepers.Game.Board
  alias Minesweepers.Game.Square
  doctest Minesweepers

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "game board creation" do
    %Board{cols: cols, rows: rows, squares: squares} = Board.new(2,2,0)
    assert squares == %{
      {0,0} => %Square{neighbors: 0, type: :empty},
      {0,1} => %Square{neighbors: 0, type: :empty},
      {1,0} => %Square{neighbors: 0, type: :empty},
      {1,1} => %Square{neighbors: 0, type: :empty}
    }

    %Board{cols: cols, rows: rows, squares: squares} = Board.new(2,2,1)
    assert squares == %{
      {0,0} => %Square{neighbors: 3, type: :bomb},
      {0,1} => %Square{neighbors: 3, type: :bomb},
      {1,0} => %Square{neighbors: 3, type: :bomb},
      {1,1} => %Square{neighbors: 3, type: :bomb}
    }
  end

  test "flip all squares" do
    board = Board.new(2,2,0)
    assert Board.hit_square(board, {1,1}) |> Enum.count == 4

  end
end
