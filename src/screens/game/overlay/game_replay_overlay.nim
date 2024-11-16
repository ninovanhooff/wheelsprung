{.push raises: [].}

import playdate/api
import std/options
import screens/game/game_types
import game_overlay_components
import common/shared_types
import common/utils
import navigation/navigator

const 
  REPLAY_OVERLAY_TIMEOUT = 3.0.Seconds


proc updateGameReplayOverlay*(state: GameState): bool =
  ## Returns true when game update can continue or false when the replay is paused
  if state.gameReplayState.isNone:
    return true

  let buttonState = playdate.system.getButtonState()
  let replayState = state.gameReplayState.get
  let currentTime = getElapsedSeconds()
  if kButtonA in buttonState.pushed:
    replayState.isPaused = not replayState.isPaused
  elif kButtonB in buttonState.pushed:
    popScreen()
  
  if buttonState.pushed.anyButton: 
    # if replayState.hideOverlayAt.isSome:
    #   replayState.hideOverlayAt = none(Seconds)
    # else:
      replayState.hideOverlayAt = some(currentTime + REPLAY_OVERLAY_TIMEOUT)
  
  replayState.hideOverlayAt.expire(currentTime)
  return not replayState.isPaused



proc drawGameReplayOverlay*(state: GameState) =
  if state.gameReplayState.get.hideOverlayAt.isSome:
    let message = "Ⓑ Exit Replay | Ⓐ Resume Playback"
    drawButtonMapOverlay(message)