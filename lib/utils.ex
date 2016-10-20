defmodule Utils do
  @hex "0123456789abcedf"

  def uuid do
    UUID.uuid4()
  end

  def make_id do
    :crypto.strong_rand_bytes(16) |> :erlang.term_to_binary |> Base.encode64
  end

  def epoch_time do
    :os.system_time(:milli_seconds)
  end

  def random_hex do
    tevs = for <<a::size(4), b::size(4) <- :crypto.strong_rand_bytes(12)>>,
        n <- [a, b],
        do: String.at(@hex, n)

    tevs
    |> to_string
  end

  def random_ref() do
    :crypto.strong_rand_bytes(8) |> :erlang.term_to_binary() |> Base.encode64()
  end

  def test_match(m) do
    if {:user, name} = m do
      {:match, name}
    else
      {:nomatch}
    end
  end
end

defmodule Minesweepers.Profile do
  alias Minesweepers.Game.Board

  @profile_sz 400
  @profile_chance 0.10

  def profile_board do
    Board.new(@profile_sz, @profile_sz, @profile_chance)
    Board.new(@profile_sz, @profile_sz, @profile_chance)
    Board.new(@profile_sz, @profile_sz, @profile_chance)
    Enum.map(0..49, fn _ ->
      t0 = :os.system_time(:milli_seconds)
      Board.new(@profile_sz, @profile_sz, @profile_chance)
      t1 = :os.system_time(:milli_seconds)
      t1 - t0
    end)
  end

end

