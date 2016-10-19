defmodule Minesweepers.Records do
  import Record, only: [defrecord: 2]
  use Bitwise

  defrecord :square, [ neighbors: 0, state: :unrevealed_empty ]
  defrecord :game_info_response, [ start: 0, scores: %{} ]

  def to_struct(square(neighbors: n, state: state) = s, {row,col}) do
    %{
      neighbors: n,
      row: row,
      col: col,
      state: state
    }
  end

end
