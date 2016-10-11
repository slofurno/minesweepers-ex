defmodule Minesweepers.Records do
  import Record, only: [defrecord: 2]
  use Bitwise

  defrecord :square, [ type: :empty, neighbors: 0, row: 0, col: 0, revealed: false, flagged: false ]

  def to_struct(square(type: type, neighbors: neighbors, row: row, col: col, revealed: revealed, flagged: flagged) = s) do
    %{
      type: type,
      neighbors: neighbors,
      row: row,
      col: col,
      revealed: revealed,
      flagged: flagged
    }
  end

end
