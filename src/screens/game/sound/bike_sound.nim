import screens/game/game_types
import bike_engine, bike_squeak, bike_thud, bike_kickstart

proc initBikeSound*() =
  initBikeEngine()
  initBikeSqueak()
  initBikeThud()
  initBikeKickStart()

proc updateBikeSound*(state: GameState)=
  updateBikeEngine(state)
  updateBikeSqueak(state)
  updateBikeThud(state)
  updateBikeKickStart(state)

proc pauseBikeSound*() =
  pauseBikeEngine()