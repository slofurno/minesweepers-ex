defmodule Minesweepers.Stack do
  def start_link do
    Agent.start_link fn -> [] end
  end

  def push(pid, x) do
    Agent.update(pid, fn(xs) -> [x| xs] end)
  end

  def contains?(pid, x) do
    Agent.get(pid, fn xs -> x in xs end)
  end

  def get_all(pid) do
    Agent.get(pid, fn xs -> xs end)
  end

  def stop(pid) do
    Agent.stop(pid)
  end
end
