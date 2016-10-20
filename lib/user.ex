defmodule Minesweepers.User do
  alias Ecto.Adapters.SQL
  alias Minesweepers.Repo

  def create(email, pass) do
    id = Utils.uuid
    hash = Comeonin.Bcrypt.hashpwsalt(pass)
    sql = "insert into accounts (id, email, hash) values($1,$2,$3)"
    SQL.query(Repo, sql, [id, email, hash])
    %{id: id, email: email}
  end

  def create_login(account) do
    token = Utils.uuid
    sql = "insert into logins (id, account) values ($1, $2)"
    SQL.query(Repo, sql, [token, account])
    {:ok, token}
  end

  defp match_rows({:ok, %{num_rows: num_rows, rows: rows}}) when num_rows > 0, do: rows

  defp match_user({:ok, %{num_rows: num_rows, rows: rows}}) when num_rows > 0 do
    [[id, email, hash]|_] = rows
    {:ok, %{id: id, email: email, hash: hash}}
  end

  defp match_user(_) do
    {:error, "no matching user"}
  end

  def get_account(token) do
    sql = "select accounts.* from logins left join accounts on accounts.id = logins.account where logins.id = $1"
    res = SQL.query(Repo, sql, [token])
    match_user(res)
  end

  defp check_pass(pass, hash) do
    if Comeonin.Bcrypt.checkpw(pass, hash) do
      {:ok}
    else
      {:error}
    end
  end

  defp match_login_account({:ok, %{num_rows: num_rows, rows: rows}}) when num_rows > 0 do
    [[account]|_] = rows
    {:ok, %{account: account}}
  end

  defp match_login_account(_) do
    {:error, "no matching rows"}
  end


  defp get_account_by_email(email) do
    sql = "select * from accounts where email = $1"
    SQL.query(Repo, sql, [email])
    |> match_user
  end

  def auth(email, pass) do
    with {:ok, user} <- get_account_by_email(email),
         {:ok} <- check_pass(pass, user.hash),
         {:ok, token} <- create_login(user.id) do
         {:ok, token}
    end
    |> case do
      {:ok, token} -> {:ok, token}
      _ -> {:error}
    end
  end
end
