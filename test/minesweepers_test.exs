defmodule MinesweepersTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import Minesweepers.Records
  alias Minesweepers.Game
  alias Minesweepers.Game.Board
  alias Minesweepers.Game.Square
  doctest Minesweepers

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "game board creation" do
    %Board{cols: cols, rows: rows, squares: squares} = Board.new(2,2,0.0)
    assert squares == %{
      {0,0} => square(neighbors: 0, type: :empty, row: 0, col: 0),
      {0,1} => square(neighbors: 0, type: :empty, row: 0, col: 1),
      {1,0} => square(neighbors: 0, type: :empty, row: 1, col: 0),
      {1,1} => square(neighbors: 0, type: :empty, row: 1, col: 1)
    }

    %Board{cols: cols, rows: rows, squares: squares} = Board.new(2,2,1.0)
    assert squares == %{
      {0,0} => square(neighbors: 3, type: :bomb, row: 0, col: 0),
      {0,1} => square(neighbors: 3, type: :bomb, row: 0, col: 1),
      {1,0} => square(neighbors: 3, type: :bomb, row: 1, col: 0),
      {1,1} => square(neighbors: 3, type: :bomb, row: 1, col: 1)
    }
  end

  test "flip all squares" do
    board = Board.new(2,2,0.0)
    {:empty, board, flipped} = Board.hit_square(board, {1,1})
    assert flipped |> Enum.count == 4
    IO.inspect(flipped)
  end

  test "hitting a mine" do
    game = Game.new(10, 10, 1.0)
    click = %Minesweepers.ClickEvent{game: game.id, pos: {4,4}}
    assert Game.player_click(click) == :explode
  end

  test "has neighbors" do
    board = Board.new(5, 5, 1.0)
    mines = Board.neighbors(board, {2,2})
    |> Enum.count

    IO.inspect(Board.neighbors(board, {2,2}))
    assert mines == 8
  end

  test "reveal all squares" do
    rows = 10
    cols = 10

    game = Game.new(rows, cols, 0.0)
    click = %Minesweepers.ClickEvent{game: game.id, pos: {4,4}}
    Game.player_click(click)
    state = Game.get_state(game.id)

    is_revealed_and_empty = fn
      square(revealed: true, type: :empty) -> true
      _ -> false
    end

    revealed_and_empty = Board.list_squares(state.board)
    |> Enum.filter(is_revealed_and_empty)
    |> Enum.count

    assert revealed_and_empty == rows*cols
  end

  test "interacting with mines" do
    board = Board.new(1, 2, 1.0)
    {type, board} = Board.mark_square(board, {0, 0})
    assert type == :bomb

    #FIXME: is this order specified?
    first = Board.list_squares(board) |> Enum.fetch!(0)
    assert first == square(row: 0, col: 0, flagged: true, neighbors: 1, revealed: true, type: :bomb)

    pos = {0, 1}
    {type, board} = Board.hit_square(board, pos)
    assert type == :bomb
    first = Board.list_squares(board) |> Enum.fetch!(1)
    assert first == square(row: 0, col: 1, flagged: false, neighbors: 1, revealed: true, type: :bomb)

  end

  test "nif neighbor calc" do
    b = Board.new(1000,1000,0.5)

    p = 901
    xs = for y <- p-1..p+1,
    x <- p-1..p+1,
    y != p || x != p,
    do: {x, y}

    is_bomb = fn
      square(type: :bomb) -> true
      _ -> false
    end

    neighbors = xs
    |> Enum.map(fn x -> b.squares[x] end)
    |> Enum.filter(is_bomb)
    |> Enum.count


    square(neighbors: computed_neighbors) = b.squares[{p,p}]

    assert neighbors == computed_neighbors
  end
end
