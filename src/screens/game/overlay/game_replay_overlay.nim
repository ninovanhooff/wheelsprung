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


proc updateGameReplayOverlay*(state: GameState) =
  if state.gameReplayState.isNone:
    return

  let buttonState = playdate.system.getButtonState()
  let replayState = state.gameReplayState.get
  let currentTime = getElapsedSeconds()
  if kButtonA in buttonState.pushed:
    state.isGamePaused = not state.isGamePaused
  elif kButtonB in buttonState.pushed:
    popScreen()
  
  if buttonState.pushed.anyButton: 
    replayState.hideOverlayAt = some(currentTime + REPLAY_OVERLAY_TIMEOUT)
  
  replayState.hideOverlayAt.expire(currentTime)


proc drawGameReplayOverlay*(state: GameState) =
  if state.gameReplayState.get.hideOverlayAt.isSome:
    let message = "Ⓑ Exit Replay | Ⓐ Resume Playback"
    drawButtonMapOverlay(message)