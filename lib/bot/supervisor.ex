defmodule Minesweepers.Bot.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: Minesweepers.Bot.Supervisor)
  end

  def start_bot(game) do
    Supervisor.start_child(Minesweepers.Bot.Supervisor, [game])
  end

  def init(_) do
    children = [
      worker(Minesweepers.Bot, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
