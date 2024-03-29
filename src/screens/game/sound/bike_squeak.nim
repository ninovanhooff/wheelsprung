import playdate/api
import chipmunk7
import utils
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
  let forkImpulse: Float = state.forkArmSpring.impulse
  if not contractPlayer.isPlaying and forkImpulse > contractImpulseThreshold:
    print("playing contract squeak for impulse: " & $forkImpulse)
    contractPlayer.play(1, 1.0)
    contractPlayer.volume=lerp(0.0, 1.0, forkImpulse/50.0)
  elif contractPlayer.isPlaying and forkImpulse <= 0.0:
    contractPlayer.stop()