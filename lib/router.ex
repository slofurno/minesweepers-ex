defmodule Minesweepers.Router do
  use Plug.Router
  use Plug.Builder
  alias Plug.Conn
  alias Minesweepers.Game

  plug :match
  plug :dispatch

  get "/api/games" do
    games = Game.list_games()
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(games))
  end

  post "/api/games" do
    id = Game.Supervisor.start_game
    send_resp(conn, 200, id)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
