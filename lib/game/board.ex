defmodule Minesweepers.Game.Board do
  alias Minesweepers.Game.Board
  alias Minesweepers.Game.Square
  alias Minesweepers.Rand
  alias Minesweepers.Stack

  defstruct [
    rows: 0,
    cols: 0,
    squares: %{}
  ]

  def new(rows, cols, chance) do
    squares = for row <- 0..rows-1,
      col <- 0..cols-1,
      into: %{},
      do: {{row, col}, make_square(chance, row, col)}

    board = %Board{squares: squares, rows: rows, cols: cols}

    squares = for row <- 0..rows-1,
      col <- 0..cols-1,
      into: %{},
      do: {{row, col}, with_neighbors(board, {row, col})}

    %Board{squares: squares, rows: rows, cols: cols}
  end

  def hit_square(%Board{squares: squares} = board, {row, col} = pos) do
    case get_square(board, pos) do
      %Square{type: :bomb} -> {:bomb}

      %Square{type: :empty, revealed: false, flagged: false} ->
        {:ok, seen} = Stack.start_link
        flip_empty(board, pos, seen)
        flipped = Stack.get_all(seen)
        Stack.stop(seen)
        squares1 = reveal_squares(squares, flipped)
        #|> Map.put(pos, %Square{squares[pos]| type: :flag})
        #infos = Enum.map(flipped, fn x -> {x, next_squares[x]} end)
        {:empty, %Board{board| squares: squares1}, flipped}

      _ -> {:ok}
    end
  end

  def mark_square(%Board{} = board, pos) do
    case get_square(board, pos) do
      %Square{type: :bomb, revealed: false, flagged: false} -> {:bomb}
      %Square{type: :empty, revealed: false, flagged: false} -> {:empty}

    end
  end

  defp flip_empty(%Board{squares: squares} = board, pos, seen) do
    if has_no_neighbors(board, pos) && !Stack.contains?(seen, pos) do
      Stack.push(seen, pos)
      neighbors(board, pos) |> Enum.map(&flip_empty(board, &1, seen))
    end
  end

  defp reveal_squares(state, squares) do
    Enum.reduce(squares, state, fn c,a ->
      Map.put(a,c,%Square{a[c]| revealed: true})
    end)
  end


  defp make_square(chance, row, col) do
    if chance > Rand.next(), do: Square.new(:bomb, row, col), else: Square.new(:empty, row, col)
  end

  defp with_neighbors(%Board{squares: squares, rows: rows, cols: cols} = board, {row, col} = pos) do
    count = neighbors(board, pos)
    |> Enum.filter(&isBomb(board, &1))
    |> Enum.count

    %Square{squares[pos]| neighbors: count }
  end

  defp neighbors(%Board{squares: squares, rows: rows, cols: cols} = board, {row, col} = pos) do
    for r <- row-1..row+1,
      c <- col-1..col+1,
      r != row || c != col,
      r >= 0,
      c >= 0,
      r < rows,
      c < cols,
      do: {r, c}
  end

  defp isBomb(board, {_row, _col} = pos) do
    %Square{type: type} = get_square(board, pos)
    type == :bomb
  end

  defp isEmpty2(board, pos) do
    %Square{type: type} = get_square(board, pos)
    type == :empty
  end

  defp has_no_neighbors(board, pos) do
    %Square{neighbors: neighbors} = get_square(board, pos)
    neighbors == 0
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
