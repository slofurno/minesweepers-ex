defmodule Minesweepers.Game.Supervisor do
  use Supervisor
  alias Minesweepers.Game

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: Minesweepers.Game.Supervisor)
  end

  def start_game(rows, cols, chance) do
    id = Utils.uuid
    Supervisor.start_child(Minesweepers.Game.Supervisor, [id, rows, cols, chance])
    id
  end

  def start_game do
    start_game(1000,1000,0.17)
  end

  def init(_) do
    children = [
      worker(Minesweepers.Game, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
