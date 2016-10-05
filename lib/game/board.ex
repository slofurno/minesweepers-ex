defmodule Minesweepers.Game.Board do
  alias Minesweepers.Game.Board
  alias Minesweepers.Game.Square
  alias Minesweepers.Rand
  alias Minesweepers.Stack
  alias Minesweepers.Utils

  defstruct [
    rows: 0,
    cols: 0,
    squares: %{}
  ]

  @offsets [{-1,-1}, {-1,0}, {-1,1}, {0,-1}, {0,1}, {1,-1}, {1,0}, {1,1}]

  def new(rows, cols, chance) do
    xs = for row <- 0..rows-1,
      col <- 0..cols-1,
      do: {row, col}

    squares = populate_board(%{}, chance, xs)
    |> populate_neighbors(rows, cols, xs)

    %Board{squares: squares, rows: rows, cols: cols}
  end

  defp populate_board(board, p, []), do: board

  defp populate_board(board, p, [x|xs]) do
    {row, col} = x
    board = Map.put(board, x, make_square(p, row, col))
    populate_board(board, p, xs)
  end

  defp populate_neighbors(squares, _rows, _cols, []), do: squares

  defp populate_neighbors(squares, rows, cols, [x|xs]) do
    squares = Map.put(squares, x, count_adjacent_bombs(squares, rows, cols, x))
    populate_neighbors(squares, rows, cols, xs)
  end

  def hit_square(%Board{squares: squares} = board, {row, col} = pos) do
    case get_square(board, pos) do
      %Square{type: :bomb} ->
        squares1 = reveal_square(squares, pos)
        {:bomb, %Board{board| squares: squares1}}

      %Square{type: :empty, revealed: false, flagged: false} ->
        flipped = flip_empty(board, pos)
        squares1 = reveal_squares(squares, flipped)
        {:empty, %Board{board| squares: squares1}, flipped}

      _ ->
        {:ok}
    end
  end

  def mark_square(%Board{squares: squares} = board, pos) do
    case get_square(board, pos) do
      %Square{type: :bomb, revealed: false} ->
        squares1 = flag_square(squares, pos)
        {:bomb, %Board{board| squares: squares1}}

      %Square{type: :empty, revealed: false} ->
        {:empty}

      _ ->
        {:ok}

    end
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
      Map.put(a,c,%Square{a[c]| revealed: true})
    end)
  end

  defp reveal_square(squares, pos) do
    Map.put(squares, pos, %Square{squares[pos]| revealed: true})
  end

  defp flag_square(squares, pos) do
    Map.put(squares, pos, %Square{squares[pos]| revealed: true, flagged: true})
  end

  defp make_square(chance, row, col) do
    if chance > Rand.next(), do: Square.new(:bomb, row, col), else: Square.new(:empty, row, col)
  end

  defp count_adjacent_bombs_(squares, _rows, _cols, {_row, _col} = pos, [], n) do
    %Square{squares[pos]| neighbors: n}
  end

  defp count_adjacent_bombs_(squares, rows, cols, {row, col} = pos, [x|xs], n) do
    {r, c} = x
    row = row + r
    col = col + c

    cond do
      row < 0 || col < 0 || row >= rows || col >= cols ->
        count_adjacent_bombs_(squares, rows, cols, pos, xs, n)

      squares[{row,col}].type == :bomb ->
      #is_bomb(board, {row, col}) ->
        count_adjacent_bombs_(squares, rows, cols, pos, xs, n + 1)

      true ->
        count_adjacent_bombs_(squares, rows, cols, pos, xs, n)
    end
  end

  defp count_adjacent_bombs(squares, rows, cols, {_row, _col} = pos) do
    count_adjacent_bombs_(squares, rows, cols, pos, @offsets, 0)
  end

  defp with_neighbors(%Board{squares: squares, rows: rows, cols: cols} = board, {row, col} = pos) do
    count = neighbors(board, pos)
    |> adjacent_bomb_count(board, 0)
    #|> Enum.filter(&is_bomb(board, &1))
    #|> Enum.count

    %Square{squares[pos]| neighbors: count }
  end


  defp valid_square({r, c} = pos, rows, cols) do
    r >= 0 && c >= 0 && r < rows && c < cols
  end

  # 5->6
  defp adjacent_bomb_count([x|xs], board, n) do
    if is_bomb(board, x) do
      adjacent_bomb_count(xs, board, n+1)
    else
      adjacent_bomb_count(xs, board, n)
    end
  end

  defp adjacent_bomb_count([], _board, n), do: n

  # 4->5
  defp valid_neighbors([x|xs], rows, cols, yys) do
    if valid_square(x, rows, cols) do
      valid_neighbors(xs, rows, cols, [x|yys])
    else
      valid_neighbors(xs, rows, cols, yys)
    end
  end

  defp valid_neighbors([], _rows, _cols, yys), do: yys

  def neighbors(%Board{squares: squares, rows: rows, cols: cols} = board, {row, col} = pos) do

    # {600,200}
    Enum.map(@offsets, fn {r,c} -> {r+row, c+col} end)
    |> valid_neighbors(rows, cols, [])

    # {900,200}
    #|> Enum.filter(&valid_square(&1, rows, cols))
    #|> Enum.filter(fn {r,c} -> r >= 0 && c >= 0 && r < rows && c < cols end)

    #{800,200}
    #for r <- row-1..row+1,
    #  c <- col-1..col+1,
    #  r != row || c != col,
    #  r >= 0,
    #  c >= 0,
    #  r < rows,
    #  c < cols,
    #  do: {r, c}
  end

  defp is_bomb(board, {_row, _col} = pos) do
    %Square{type: type} = get_square(board, pos)
    type == :bomb
  end

  defp has_no_neighbors(board, pos) do
    %Square{neighbors: neighbors} = get_square(board, pos)
    neighbors == 0
  end

  def get_square(%Board{squares: squares} = board, {row, col} = pos) do
    squares[pos]
  end

  defp square_at(squares, x, y) do
  end
end
