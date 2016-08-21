defmodule Minesweepers.Rand do
  #@on_load :reseed
  def reseed do
    :random.seed(:os.timestamp())
  end

  def int(number) do
    :random.uniform(number)
  end

  def next do
    :random.uniform()
  end
end
