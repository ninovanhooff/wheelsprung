import game_types

proc initGameCoins*(state: GameState) =
  # asssigment by copy
  state.remainingCoins = state.level.coins

  
