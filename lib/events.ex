defmodule Minesweepers.ClickEvent do
  defstruct [
    player: :nil,
    game: :nil,
    pos: :nil,
    right: false,
    from: :nil
  ]
end

defmodule Minesweepers.RevealEvent do
  defstruct [
    type: "reveal",
    player: :nil,
    squares: [],
    score: 0
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

defmodule Minesweepers.PlayerEvent do
  defstruct [
    type: "player",
    player: :nil,
    message: ""
  ]
end
