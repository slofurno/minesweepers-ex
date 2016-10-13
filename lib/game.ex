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
  import Minesweepers.Records

  defstruct [
    id: "",
    board: :nil,
    players: [],
    events: [],
    history: [],
    scores: %{}
  ]

  def new(id, rows, cols, chance) do
    board = Board.new(rows, cols, chance)
    %Game{board: board, id: id}
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

  def start_link(id, rows, cols, chance) do
    GenServer.start_link(__MODULE__, [id, rows, cols, chance], name: via_tuple(id))
  end

  def init([id, rows, cols, chance]) do
    {:ok, new(id, rows, cols, chance)}
  end

  def list_games do
    match = {{:n, :l, {:game, :_}}, :_, :_}
    guard = []
    res = [:"$$"]
    for [{_, _, {:game, id}}|_] <- :gproc.select([{match, guard, res}]), do: id
  end

  def player_click(%ClickEvent{game: game} = event) do
    whereis(game) |> GenServer.cast(event)
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

  def handle_cast(%ClickEvent{player: player, pos: pos, right: true, from: from}, %Game{board: board} = game) do
    case Board.mark_square(board, pos) do
      {:bomb, board} ->
        changed = board.squares[pos]
        broadcast(game, %RevealEvent{squares: [ to_struct(changed) ]})
        send(from, {:score, 10, pos})
        {:noreply, %Game{game| board: board, history: [changed| game.history] }}

      {:empty} ->
        send(from, {:score, -200, pos})
        {:noreply, game}

      {:ok} ->
        {:noreply, game}
    end
  end

  def handle_cast(%ClickEvent{player: player, pos: pos, from: from}, %Game{board: board} = game) do
    case Board.hit_square(board, pos) do
      {:empty, board, flipped} ->
        changed = flipped |> Enum.map(fn x -> board.squares[x] end)
        serializable_changes = changed|> Enum.map(&to_struct/1)
        broadcast(game, %RevealEvent{squares: serializable_changes})
        send(from, {:score, Enum.count(changed), pos})
        {:noreply, %Game{game| board: board, history: changed ++ game.history}}

      {:bomb, board} ->
        changed = board.squares[pos]
        broadcast(game, %RevealEvent{squares: [ to_struct(changed) ]})
        send(from, {:score, -200, pos})
        {:noreply, %Game{game| board: board, history: [changed| game.history]}}

      {:ok} ->
        {:noreply, game}
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

  def handle_call(:initial_state, _from, %Game{ board: %Board{ rows: rows, cols: cols}, history: history } = state) do
    xs = history |> Enum.map(&to_struct/1)
    {:reply, %{rows: rows, cols: cols, squares: xs}, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  defp broadcast(%Game{id: id}, e) do
    :gproc.send({:p, :l, {:game, id}}, {:game_event, e})
  end

  def subscribe(game) do
    :gproc.reg({:p, :l, {:game, game}})
  end

  def whereis(game) do
    :gproc.whereis_name({:n, :l, {:game, game}})
  end

  def via_tuple(game) do
    {:via, :gproc, {:n, :l, {:game, game}}}
  end
end

