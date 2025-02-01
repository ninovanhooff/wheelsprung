import std/random
import playdate/api
import chipmunk7
import common/[utils, audio_utils]
import screens/game/game_types
import system
import cache/sound_cache

const
  minContactImpulse: Float = 25.0
  maxContactImpulse: Float = 200.0

var
  thudPlayers: seq[SamplePlayer]
  curPlayer: SamplePlayer
  curContactImpulse: Float = 0.0
  prevContactImpulse: Float = 0.0 # last Frame's contact impulse

proc getRandomThud(): SamplePlayer=
  thudPlayers[rand(thudPlayers.high)]

proc initBikeThud*() =
  if thudPlayers.len > 0: return # already initialized
  # print("initBikeThud")

  try:
    thudPlayers.add(getOrLoadSamplePlayer(SampleId.BikeThud1))
    thudPlayers.add(getOrLoadSamplePlayer(SampleId.BikeThud2))
    thudPlayers.add(getOrLoadSamplePlayer(SampleId.BikeThud3))
    
    curPlayer = getRandomThud()
  except:
    quit(getCurrentExceptionMsg(), 1)

proc getFirstContactImpulse(arb: Arbiter) =
    # add impulse if a wheel just hit the ground
    if arb.isFirstContact:
      curContactImpulse = max(curContactImpulse, arb.totalImpulse.vlength)

proc updateBikeThud*(state: GameState) =
  curContactImpulse = 0.0
  state.frontWheel.eachArbiter(getFirstContactImpulse)
  state.rearWheel.eachArbiter(getFirstContactImpulse)
  
  if prevContactImpulse == 0.0 and 
    curContactImpulse > minContactImpulse and 
    not curPlayer.isPlaying:
      curPlayer = getRandomThud()
      curPlayer.playVariation()
      curPlayer.volume=lerp(0.0, 1.0, curContactImpulse / maxContactImpulse)
  prevContactImpulse = curContactImpulse
