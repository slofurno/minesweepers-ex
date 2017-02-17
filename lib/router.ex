defmodule Minesweepers.Router do
  use Plug.Router
  use Plug.Builder
  alias Plug.Conn
  alias Minesweepers.Game
  alias Minesweepers.User
  alias Minesweepers.Bot

  plug :match
  plug :dispatch

  get "/api/games" do
    games = Game.list_games()
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(games))
  end

  get "/api/games/:id" do
    IO.inspect(id)

    send_resp(conn, 200, "ok")
  end

  post "/api/games" do
    {:ok, body, conn} = read_body(conn)
    %{rows: rows, cols: cols, bots: bots} = Poison.decode!(body, as: %GameRequest{})
    game = Game.Supervisor.start_game(rows, cols, 0.206)
    Enum.each(1..bots, fn _ -> Bot.Supervisor.start_bot(game) end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(game))
  end

  post "/api/users" do
    %{id: id} = User.create(Utils.uuid, Utils.uuid)
    {:ok, token} = User.create_login(id)

    send_resp(conn, 200, Poison.encode!(%{id: id, token: token}))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end

