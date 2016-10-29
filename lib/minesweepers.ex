defmodule Minesweepers do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, nil, [], [dispatch: dispatch, port: 4001]),
      supervisor(Minesweepers.Repo, []),
      supervisor(Minesweepers.Game.Supervisor, []),
      supervisor(Minesweepers.Bot.Supervisor, [])
      # Define workers and child supervisors to be supervised
      # worker(Minesweepers.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Minesweepers.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [{:_, [
          {"/ws", Minesweepers.Socket, []},
          {:_, Plug.Adapters.Cowboy.Handler, {Minesweepers.Router, []}}
        ]}]
  end
end
