defmodule Minesweepers.ClickEvent do
  defstruct [
    player: :nil,
    game: :nil,
    pos: :nil,
    right: false
  ]
end

defmodule Minesweepers.RevealEvent do
  defstruct [
    type: "reveal",
    player: :nil,
    squares: []
  ]
end

defmodule Minesweepers.FlagEvent do
  defstruct [
    type: "flag",
    pos: :nil,
    player: :nil
  ]
end

defmodule Minesweepers.BombEvent do
  defstruct [
    type: "bomb",
    pos: :nil,
    player: :nil
  ]
end
