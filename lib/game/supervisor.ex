defmodule Minesweepers.Game.Supervisor do
  use Supervisor
  alias Minesweepers.Game

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: Minesweepers.Game.Supervisor)
  end

  def start_game(%Game{} = game) do
    Supervisor.start_child(Minesweepers.Game.Supervisor, [game])
  end

  def init(_) do
    children = [
      worker(Minesweepers.Game, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
