defmodule Minesweepers.Game do
  use GenServer
  alias Minesweepers.Game
  alias Minesweepers.Game.Board
  alias Minesweepers.Game.Square
  alias Minesweepers.ClickEvent
  alias Minesweepers.FlagEvent
  alias Minesweepers.RevealEvent
  alias Minesweepers.BombEvent
  alias Minesweepers.PlayerEvent
  alias Minesweepers.Utils

  defstruct [
    id: "",
    board: :nil,
    players: [],
    events: []
  ]

  def new(rows, cols, chance) do
    board = Board.new(rows, cols, chance)
    game = %Game{board: board, id: Utils.uuid}
    start_link(game)
    game
  end

  def new do
    new(150, 100, 0.10)
    #board = Board.new(400, 400, 0.10)
    #game = %Game{board: board, id: Utils.uuid}
    #start_link(game)
    #game
  end

  def profile_board do
    t0 = :os.system_time(:milli_seconds)
    for _ <- 0..9, do: Board.new(400,400,0.1)
    t1 = :os.system_time(:milli_seconds)
    t1 - t0
  end

  def start_link(%Game{id: id} = game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(id))
  end

  def add_player(game, player) do

  end

  def list_games do
    match = {{:n, :l, {:game, :_}}, :_, :_}
    guard = []
    res = [:"$$"]
    for [{_, _, {:game, id}}|_] <- :gproc.select([{match, guard, res}]), do: id
  end

  def player_click(%ClickEvent{game: game} = event) do
    whereis(game) |> GenServer.call(event)
  end

  def get_state(game) do
    whereis(game) |> GenServer.call(:state)
  end

  def visible_state(game) do
    %Game{board: board, players: players} = get_state(game)
    Board.list_squares(board) |> Enum.filter(&Square.is_revealed/1)
  end

  def handle_call(%ClickEvent{player: player, pos: pos, right: true}, _from, %Game{board: board} = game) do
    case Board.mark_square(board, pos) do
      {:bomb, board} ->
        broadcast(game, %RevealEvent{squares: [ board.squares[pos] ]})
        {:reply, :ok, %Game{game| board: board}}

      {:empty} ->
        {:reply, :explode, game}

      {:ok} ->
        {:reply, :notok, game}
    end
  end

  def handle_call(%ClickEvent{player: player, pos: pos}, _from, %Game{board: board} = game) do
    case Board.hit_square(board, pos) do
      {:empty, board, flipped} ->
        updated = Enum.map(flipped, fn x -> board.squares[x] end)
        broadcast(game, %RevealEvent{squares: updated})
        {:reply, :ok, %Game{game| board: board}}

      {:bomb, board} ->
        broadcast(game, %RevealEvent{squares: [ board.squares[pos] ]})
        {:reply, :explode, %Game{game| board: board}}

      {:ok} ->
        {:reply, :notok, game}
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

