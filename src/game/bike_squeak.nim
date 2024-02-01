import playdate/api
import chipmunk7
import utils
import game_types

const
  contractThreshold = 20.0

var
  contractPlayer: SamplePlayer

proc initBikeSqueak*()=
  try:
    contractPlayer = playdate.sound.newSamplePlayer("/audio/suspension/suspension_contract_adpcm")
  except:
    print(getCurrentExceptionMsg())

proc updateBikeSqueak*(state: GameState) =
  let forkImpulse: Float = state.forkArmSpring.impulse
  if not contractPlayer.isPlaying and forkImpulse > contractThreshold:
    contractPlayer.play(1, 1.0)
    contractPlayer.volume=lerp(0.0, 1.0, forkImpulse/50.0)
  elif contractPlayer.isPlaying and forkImpulse <= 0.0:
    contractPlayer.stop()
  print("forkImpulse: " & $forkImpulse)