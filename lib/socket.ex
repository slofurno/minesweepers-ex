defmodule Minesweepers.Socket do
  alias Minesweepers.Game
  alias Minesweepers.User
  alias Minesweepers.ClickEvent

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  defp query_string(req) do
    {qs, _} = :cowboy_req.qs(req)
    URI.decode_query(qs)
  end

  defp match_query_string(%{"gameid" => gameid, "token" => token}) do
    {:ok, token, gameid}
  end

  defp match_query_string(_), do: {:error, "missing query string params"}

  defp params_from_qs(req) do
    req |> query_string |> match_query_string
  end

  #TODO: heartbeat instead of longer timeout
  def websocket_init(_type, req, _opts) do
    with {:ok, token, gameid} <- params_from_qs(req),
      {:ok, account} <- User.get_account(token) do
        {:ok, account, gameid}
    end
    |> case do
      {:ok, account, gameid} ->
        send self, {:init, gameid}
        {:ok, req, %{account: account.id, game: gameid}, 480000}

      rr ->
        IO.inspect(rr)
        {:shutdown, req}
    end
  end

  def websocket_handle({:text, message}, req, %{account: account, game: game} = state) do
    case Poison.decode!(message, as: %{}) do
      %{"type" => "click", "pos" => [row,col], "right" => right} ->
        event = %ClickEvent{player: account, game: game, pos: {row, col}, right: right, from: self}
        Game.player_click(event)

      _ -> false
    end

    {:ok, req, state}
  end

  def websocket_info({:init, game}, req, state) do
    Game.subscribe(game)
    res = %{type: "init", state: Game.get_initial_state(game)} |> Poison.encode!
    {:reply, {:text, res}, req, state}
  end

  def websocket_info({:game_event, e}, req, state) do
    res = %{type: "update", update: e} |>  Poison.encode!
    {:reply, {:text, res}, req, state}
  end

  def websocket_info({:score, points, {row, col}}, req, state) do
    res = %{type: "score", points: points, pos: [row, col]} |>  Poison.encode!
    {:reply, {:text, res}, req, state}
  end

  def websocket_info(message, req, state) do
    IO.inspect(message)
    {:reply, {:text, message}, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    IO.inspect "websocket d/c"
    :ok
  end
end
