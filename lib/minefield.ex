defmodule Minefield do
  @on_load :init

  def init do
    :erlang.load_nif('./mine_nif', 0)
  end

  def generate_minefield(rows, cols, chance) do
    raise "nif library not loaded"
  end
end

