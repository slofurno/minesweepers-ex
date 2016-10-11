defmodule Minesweepers.Game.Board do
  import Minesweepers.Records
  alias Minesweepers.Game.Board
  alias Minesweepers.Rand
  alias Minesweepers.Stack
  alias Minesweepers.Utils
  use Bitwise

  defstruct [
    rows: 0,
    cols: 0,
    squares: %{}
  ]

  @offsets [{-1,-1}, {-1,0}, {-1,1}, {0,-1}, {0,1}, {1,-1}, {1,0}, {1,1}]
  @bomb_mask 1 <<< 7

  def new(rows, cols, chance) do
    %Board{squares: make_squares(rows, cols, chance), rows: rows, cols: cols}
  end

  defp make_squares(rows, cols, chance) do
    bytes = Minefield.generate_minefield(rows, cols, chance)

    xs = for row <- 0..rows-1,
      col <- 0..cols-1,
      do: {row, col}

    map_zip(xs, bytes, %{})
  end

  defp map_zip([], _, p), do: p

  defp map_zip([x|xs], <<n :: 8, rest :: binary>>, p) do
    map_zip(xs, rest, Map.put(p, x, unpack_square(n,x)))
  end

  defp unpack_square(n, {row, col}) do
    neighbors = n &&& 7
    type = if (n &&& @bomb_mask) == @bomb_mask, do: :bomb, else: :empty

    square(type: type, neighbors: neighbors, row: row, col: col)
  end

  def hit_square(%Board{squares: squares} = board, {row, col} = pos) do
    case get_square(board, pos) do
      square(type: :bomb) ->
        squares1 = reveal_square(squares, pos)
        {:bomb, %Board{board| squares: squares1}}

      square(type: :empty, revealed: false, flagged: false) ->
        flipped = flip_empty(board, pos)
        squares1 = reveal_squares(squares, flipped)
        {:empty, %Board{board| squares: squares1}, flipped}

      _ ->
        {:ok}
    end
  end

  def mark_square(%Board{squares: squares} = board, pos) do
    case get_square(board, pos) do
      square(type: :bomb, revealed: false) ->
        squares1 = flag_square(squares, pos)
        {:bomb, %Board{board| squares: squares1}}

      square(type: :empty, revealed: false) ->
        {:empty}

      _ ->
        {:ok}

    end
  end

  defp valid_square({r, c} = pos, rows, cols) do
    r >= 0 && c >= 0 && r < rows && c < cols
	end

  defp valid_neighbors([x|xs], rows, cols, yys) do
    if valid_square(x, rows, cols) do
      valid_neighbors(xs, rows, cols, [x|yys])
    else
      valid_neighbors(xs, rows, cols, yys)
    end
  end

	defp valid_neighbors([], _rows, _cols, yys), do: yys

  def neighbors(%Board{squares: squares, rows: rows, cols: cols} = board, {row, col} = pos) do
    Enum.map(@offsets, fn {r,c} -> {r+row, c+col} end)
    |> valid_neighbors(rows, cols, [])
  end

  def list_squares(%Board{squares: squares} = board) do
    for {_, square} <- Map.to_list(squares), do: square
  end

  defp flip_empty(%Board{squares: squares} = board, pos, seen \\ []) do
    cond do
      pos in seen -> seen

      has_no_neighbors(board, pos) ->
        neighbors(board, pos) |> Enum.reduce([pos| seen], fn c, a -> flip_empty(board, c, a) end)

      true -> [pos| seen]
    end
  end

  defp reveal_squares(squares, revealed) do
    Enum.reduce(revealed, squares, fn c,a ->
      Map.put(a, c, square(a[c], revealed: true))
    end)
  end

  defp reveal_square(squares, pos) do
    Map.put(squares, pos, square(squares[pos], revealed: true))
  end

  defp flag_square(squares, pos) do
    Map.put(squares, pos, square(squares[pos], revealed: true, flagged: true))
  end

  defp is_bomb(board, {_row, _col} = pos) do
    square(type: type) = get_square(board, pos)
    type == :bomb
  end

  defp has_no_neighbors(board, pos) do
    square(neighbors: neighbors) = get_square(board, pos)
    neighbors == 0
  end

  def get_square(%Board{squares: squares} = board, {row, col} = pos) do
    squares[pos]
  end
end
