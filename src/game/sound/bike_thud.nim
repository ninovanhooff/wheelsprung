import std/random
import playdate/api
import chipmunk7
import utils
import game/game_types
import system

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
  try:
    for i in 1..3:
      thudPlayers.add(playdate.sound.newSamplePlayer("/audio/thud/thud_" & $i))
    
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
      curPlayer.play(1, rand(0.9f .. 1.1f))
      curPlayer.volume=lerp(0.0, 1.0, curContactImpulse / maxContactImpulse)
  prevContactImpulse = curContactImpulse