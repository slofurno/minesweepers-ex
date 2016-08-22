defmodule MinesweepersTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias Minesweepers.Game
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
    {:empty, board, flipped} = Board.hit_square(board, {1,1})
    assert flipped |> Enum.count == 4
    IO.inspect(flipped)
  end

  test "hitting a mine" do
    game = Game.new(10, 10, 1)
    click = %Minesweepers.ClickEvent{game: game.id, pos: {4,4}}
    assert Game.player_click(click) == :explode
  end

  test "reveal all squares" do
    rows = 10
    cols = 10

    game = Game.new(rows, cols, 0)
    click = %Minesweepers.ClickEvent{game: game.id, pos: {4,4}}
    Game.player_click(click)
    state = Game.get_state(game.id)

    revealed_and_empty = Board.list_squares(state.board)
    |> Enum.filter(fn square -> square.revealed && square.type == :empty end)
    |> Enum.count

    assert revealed_and_empty == rows*cols
  end
end
