defmodule Minesweepers.Socket do
  alias Minesweepers.Game
  alias Minesweepers.Utils
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
        #Player.new(account.id)
        send self, {:init, gameid}
        {:ok, req, %{account: account.id, game: gameid}, 480000}

      rr ->
        IO.insect(rr)
        {:shutdown, req}
    end
  end

  defp start_game do
    id = Utils.uuid
    Game.start_link(id)
    %{type: "game_started", id: id}
  end

  def websocket_handle({:text, message}, req, %{account: account, game: game} = state) do
    case Poison.decode!(message, as: %{}) do
      %{"type" => "click", "pos" => [row,col], "right" => right} ->
        event = %ClickEvent{player: account, game: game, pos: {row, col}, right: right}
        res =  Game.player_click(event) |> Poison.encode!
        {:reply, {:text, res}, req, state}

      _ -> {:ok, req, state}
    end
  end

  def websocket_info({:message, message}, req, state) do
    IO.inspect({"info1", message})
    {:reply, {:text, message}, req, state}
  end

  def websocket_info({:turn, changed}, req, state) do
    IO.inspect({"turn recv:", changed})
    {:noreply, req, state}
  end

  def websocket_info({:init, game}, req, state) do
    Game.subscribe(game)
    res = Game.visible_state(game) |> Poison.encode!
    {:reply, {:text, res}, req, state}
  end

  def websocket_info({:game_event, e}, req, state) do
    res = Poison.encode!(e)
    {:reply, {:text, res}, req, state}
  end

  def websocket_info(message, req, state) do
    IO.inspect(message)
    {:reply, {:text, message}, req, state}
  end

  defp message_self(message) do
    m = Poison.encode!(message)
    m |> IO.inspect
    send self, {:message, m}
  end

  def websocket_terminate(_reason, _req, _state) do
    IO.inspect "websocket d/c"
    :ok
  end
end
