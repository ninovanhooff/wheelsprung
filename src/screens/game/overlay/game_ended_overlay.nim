{.push raises: [].}

import options
import screens/game/game_types
import common/shared_types
import game_overlay_components

proc message(gameResult: GameResult): string =
  case gameResult.resultType
  of GameResultType.LevelComplete:
    return "Ⓑ Restart | Ⓐ Level Complete"
  of GameResultType.GameOver:
    return "Ⓑ Game Over | Ⓐ Restart"

proc drawGameEndedOverlay*(state: GameState) =
  drawButtonMapOverlay(state.gameResult.get.message)