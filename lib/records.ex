defmodule Minesweepers.Records do
  import Record, only: [defrecord: 2]
  use Bitwise

  defrecord :square, [ neighbors: 0, row: 0, col: 0, state: :unrevealed_empty]

  def to_struct(square(neighbors: n, row: row, col: col, state: state) = s) do
    %{
      neighbors: n,
      row: row,
      col: col,
      state: state
    }
  end

end
