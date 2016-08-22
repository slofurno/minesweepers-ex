defmodule Minesweepers.Game do
  use GenServer
  alias Minesweepers.Game
  alias Minesweepers.Game.Board
  alias Minesweepers.ClickEvent
  alias Minesweepers.FlagEvent
  alias Minesweepers.RevealEvent
  alias Minesweepers.BombEvent
  alias Minesweepers.PlayerEvent

  defstruct [
    id: UUID.uuid4(),
    board: Board.new(100, 100, 0.1),
    players: [],
    events: []
  ]

  def new(rows, cols, chance) do
    board = Board.new(rows, cols, chance)
    game = %Game{board: board}
    start_link(game)
    game
  end

  def new do
    game = %Game{}
    start_link(game)
    game
  end

  def add_player(game, player) do

  end

  def player_click(%ClickEvent{game: game} = event) do
    whereis(game) |> GenServer.call(event)
  end

  def get_state(game) do
    whereis(game) |> GenServer.call(:state)
  end

  def start_link(%Game{id: id} = game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(id))
  end

  def handle_call(%ClickEvent{player: player, pos: pos, right: true}, _from, %Game{board: board} = game) do
    case Board.mark_square(board, pos) do
      {:bomb, board} ->
        broadcast(game, %FlagEvent{player: player, pos: pos})
        {:reply, :ok, %Game{game| board: board}}
      {:empty, board} ->
        {:reply, :explode, game}
    end
  end

  def handle_call(%ClickEvent{player: player, pos: pos}, _from, %Game{board: board} = game) do
    case Board.hit_square(board, pos) do
      {:empty, board, flipped} ->
        updated = Enum.map(flipped, fn x -> board.squares[flipped] end)
        broadcast(game, %RevealEvent{squares: updated})
        {:reply, :ok, %Game{game| board: board}}

      {:bomb, board} ->
        broadcast(game, %BombEvent{pos: pos, player: player})
        {:reply, :explode, %Game{game| board: board}}

    end
  end

  def handle_call({:join, player}, _from, %Game{players: players} = game) do
    if player in players do
      {:reply, :already_exists, game}
    else
      broadcast(game, %PlayerEvent{player: player, message: "joined"})
      {:reply, :ok, %Game{game| players: [player| players]}}
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  defp broadcast(%Game{id: id}, e) do
    :gproc.send({:p, :l, {:game, id}}, {:game_event, e})
    #GenServer.cast(self, e)
  end

  def subscribe(game) do
    :gproc.reg({:p, :l, {:game, game}})
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

