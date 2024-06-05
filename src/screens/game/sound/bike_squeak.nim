import playdate/api
import std/options
import chipmunk7
import common/utils
import screens/game/game_types

const
  contractImpulseThreshold = 25.0

var
  contractPlayer: SamplePlayer

proc initBikeSqueak*()=
  if contractPlayer != nil: return # already initialized
  print("initializing bike squeak")

  try:
    contractPlayer = playdate.sound.newSamplePlayer("/audio/suspension/suspension_contract_adpcm")
  except:
    print(getCurrentExceptionMsg())

proc updateBikeSqueak*(state: GameState) =
  if state.gameResult.isSome:
    return
    
  let forkImpulse: Float = state.forkArmSpring.impulse
  if not contractPlayer.isPlaying and forkImpulse > contractImpulseThreshold:
    contractPlayer.play(1, 1.0)
    contractPlayer.volume=lerp(0.0, 1.0, forkImpulse/50.0)
  elif contractPlayer.isPlaying and forkImpulse <= 0.0:
    contractPlayer.stop()
