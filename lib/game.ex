defmodule Minesweepers.Game do
  use GenServer
  alias Minesweepers.Game
  alias Minesweepers.Game.Board
  alias Minesweepers.ClickEvent
  alias Minesweepers.FlagEvent
  alias Minesweepers.RevealEvent
  alias Minesweepers.BombEvent

  defstruct [
    id: UUID.uuid4(),
    board: Board.new(100, 100, 0.1),
    players: [],
    events: []
  ]

  def new do
    game = %Game{}
    start_link(game)
    game
  end

  def player_click(%ClickEvent{game: game} = event) do
    whereis(game) |> GenServer.call(event)
  end

  def start_link(%Game{id: id} = game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(id))
  end

  def handle_call(%ClickEvent{player: player, pos: pos, right: true}, _from, %Game{board: board} = game) do
    case Board.mark_square(board, pos) do
      {:bomb, board} ->
        broadcast(%FlagEvent{player: player, pos: pos})
        {:reply, :ok, %Game{game| board: board}}
      {:empty, board} ->
        {:reply, :explode, game}
    end
  end

  def handle_call(%ClickEvent{player: player, pos: pos}, _from, %Game{board: board} = game) do
    case Board.hit_square(board, pos) do
      {:empty, board, flipped} ->
        updated = Enum.map(flipped, fn x -> board[flipped] end)
        broadcast(%RevealEvent{squares: updated})
        {:reply, :ok, %Game{game| board: board}}

      {:bomb, board} ->
        broadcast(%BombEvent{pos: pos, player: player})
        {:reply, :explode, %Game{game| board: board}}

    end
  end


  defp broadcast(e) do
    GenServer.cast(self, e)
  end

  def handle_cast(%RevealEvent{} = event, %Game{players: players} = state) do
  end

  def whereis(game) do
    :gproc.whereis_name({:n, :l, {:game, game}})
  end

  def via_tuple(game) do
    {:via, :gproc, {:n, :l, {:game, game}}}
  end
end

