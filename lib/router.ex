defmodule Minesweepers.Router do
  use Plug.Router
  use Plug.Builder
  alias Plug.Conn

  plug :match
  plug :dispatch

  match _ do
    send_resp(conn, 404, "oops")
  end
end
