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
  import Minesweepers.Records

  defstruct [
    id: "",
    board: :nil,
    players: [],
    events: []
  ]

  def new(rows, cols, chance) do
    board = Board.new(rows, cols, chance)
    game = %Game{board: board, id: Utils.uuid}
    Minesweepers.Game.Supervisor.start_game(game)
    game
  end

  def new do
    new(100, 100, 0.10)
  end

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

  def start_link(%Game{id: id} = game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(id))
  end

  def loop do
    loop(Minesweepers.Game.Board.new(2000,2000,0.15))
  end

  def loop(m) do
    receive do
      {sender} -> send(sender, {:ok, m})
    end
    loop(m)
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

  def get_initial_state(game) do
    whereis(game) |> GenServer.call(:initial_state)
  end

  defp is_revealed?(square(state: state)) do
    case state do
      :unrevealed_empty -> false
      :unrevealed_bomb -> false
      _ -> true
    end
  end

  def handle_call(%ClickEvent{player: player, pos: pos, right: true}, _from, %Game{board: board} = game) do
    case Board.mark_square(board, pos) do
      {:bomb, board} ->
        broadcast(game, %RevealEvent{squares: [ to_struct(board.squares[pos]) ]})
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
        updated = flipped
          |> Enum.map(fn x -> board.squares[x] end)
          |> Enum.map(&to_struct/1)
        broadcast(game, %RevealEvent{squares: updated})
        {:reply, :ok, %Game{game| board: board}}

      {:bomb, board} ->
        broadcast(game, %RevealEvent{squares: [ to_struct(board.squares[pos]) ]})
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

  def handle_call(:initial_state, _from, %Game{ board: %Board{squares: squares, rows: rows, cols: cols} } = state) do
    xs = for row <- 0..rows-1,
    col <- 0..cols-1,
    do: {row, col}

    ys = List.foldl(xs, [], fn(x, ys) ->
      if is_revealed?(squares[x]), do: [squares[x]| ys], else: ys
    end)
    |> Enum.map(&to_struct/1)

    {:reply, %{rows: rows, cols: cols, squares: ys}, state}
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

