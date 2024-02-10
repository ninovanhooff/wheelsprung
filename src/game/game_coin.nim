import game_types
import std/sequtils
import std/sugar
import graphics_utils

proc initGameCoins*(state: GameState) =
  # asssigment by copy
  state.remainingCoins = state.level.coins

  
