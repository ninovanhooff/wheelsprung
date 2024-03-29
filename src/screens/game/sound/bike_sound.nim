import screens/game/game_types
import bike_engine, bike_squeak, bike_thud, bike_kickstart

proc initBikeSound*() =
  initBikeEngine()
  initBikeSqueak()
  initBikeThud()
  initBikeKickStart()

proc updateBikeSound*(state: GameState)=
  updateBikeKickStart(state)
  if not state.isGameStarted:
    return
  updateBikeEngine(state)
  updateBikeSqueak(state)
  updateBikeThud(state)

proc pauseBikeSound*() =
  pauseBikeEngine()