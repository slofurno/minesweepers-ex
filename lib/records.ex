defmodule Minesweepers.Records do
  import Record, only: [defrecord: 2]
  use Bitwise

  defrecord :square, [ neighbors: 0, state: :unrevealed_empty ]
  defrecord :game_info_response, [ start: 0, scores: %{} ]

  def to_struct(square(neighbors: n, state: state) = s, {row,col}) do
    %{
      n: n,
      row: row,
      col: col,
      s: state
    }
  end

end
