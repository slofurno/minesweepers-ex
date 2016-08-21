defmodule Minesweepers.Accounts do
  alias Ecto.Adapters.SQL
  alias Minesweepers.Repo

  def test do
    sql = "select * from accounts"
    SQL.query(Repo, sql)
    |> IO.inspect
  end
end
