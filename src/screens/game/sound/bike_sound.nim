import screens/game/game_types
import bike_engine, bike_squeak, bike_thud

proc initBikeSound*() =
  initBikeEngine()
  initBikeSqueak()
  initBikeThud()

proc updateBikeSound*(state: GameState)=
  if not state.isGameStarted:
    return
  updateBikeEngine(state)
  updateBikeSqueak(state)
  updateBikeThud(state)

proc pauseBikeSound*() =
  pauseBikeEngine()