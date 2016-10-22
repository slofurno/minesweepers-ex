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
    players: %{},
    history: [],
    scores: %{},
    start: 0
  ]

  def new(id, rows, cols, chance) do
    board = Board.new(rows, cols, chance)
    start = Utils.epoch_time
    %Game{board: board, id: id, start: start}
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

  def get_info(game) do
    whereis(game) |> GenServer.call(:info)
  end

  defp is_revealed?(square(state: state)) do
    case state do
      :unrevealed_empty -> false
      :unrevealed_bomb -> false
      _ -> true
    end
  end

  def handle_cast(%ClickEvent{player: player, pos: pos, right: true, from: from}, %Game{board: board, scores: scores} = game) do
    case Board.mark_square(board, pos) do
      {:bomb, board, changed} ->
        score = (scores[player] || 0) + 10
        scores = Map.put(scores, player, score)

        broadcast(game, %RevealEvent{squares: changed, player: player, score: score})
        {:noreply, %Game{game| board: board, history: changed ++ game.history, scores: scores }}

      {:empty} ->
        score = round (scores[player] || 0) * 0.2
        scores = Map.put(scores, player, score)

        broadcast(game, %RevealEvent{player: player, score: score })
        {:noreply, %Game{game| scores: scores}}

      {:ok} ->
        {:noreply, game}
    end
  end

  def handle_cast(%ClickEvent{player: player, pos: pos, from: from}, %Game{board: board, scores: scores} = game) do
    case Board.hit_square(board, pos) do
      {:empty, board, changed} ->
        score = (scores[player] || 0) + Enum.count(changed)
        scores = Map.put(scores, player, score)

        broadcast(game, %RevealEvent{squares: changed, player: player, score: score})
        {:noreply, %Game{game| board: board, history: changed ++ game.history, scores: scores}}

      {:bomb, board, changed} ->
        score = round (scores[player] || 0) * 0.2
        scores = Map.put(scores, player, score)

        broadcast(game, %RevealEvent{squares: changed, player: player, score: score})
        {:noreply, %Game{game| board: board, history: changed ++ game.history, scores: scores}}

      {:ok} ->
        {:noreply, game}
    end
  end

  def handle_cast({:name, player, name}, %Game{players: players} = game) do
    players = Map.put(players, player, name)
    broadcast(game, %PlayerEvent{player: player, name: name})
    {:noreply, %Game{game| players: players}}
  end

  def handle_call({:info}, _from, %Game{start: start, scores: scores } = game) do
    {:reply, game_info_response(start: start, scores: scores ), game}
  end

  def handle_call(:initial_state, _from, state) do
    %Game{ board: %Board{ rows: rows, cols: cols}, history: history, scores: scores, players: players } = state
    {:reply, %{rows: rows, cols: cols, squares: history, scores: scores, players: players}, state}
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

  def set_name(game, player, name) do
    whereis(game) |> GenServer.cast({:name, player, name})
  end

  def whereis(game) do
    :gproc.whereis_name({:n, :l, {:game, game}})
  end

  def via_tuple(game) do
    {:via, :gproc, {:n, :l, {:game, game}}}
  end

  defp change_score(scores, player, ds) do
    {_, scores} = Map.get_and_update(scores, player, fn
      nil -> {nil, ds}
      x -> {x, x + ds}
    end)
    scores
  end
end

