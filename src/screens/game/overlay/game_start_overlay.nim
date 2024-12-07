import playdate/api
import std/options
import common/utils
import common/shared_types
import common/graphics_utils
import screens/game/game_types
import screens/game/sound/game_sound
import screens/game/sound/bike_sound
import cache/font_cache
import cache/bitmaptable_cache
import cache/cache_preloader

const readyEndFrameIdx = 4 # the frame idx in the readyGoBitmapTable that is the last frame before it transforms in to Go!

var readyGoBitmapTable: AnnotatedBitmapTable
var titleFont: LCDFont

proc updateGameStartOverlay*(state: GameState) =
  if state.gameStartState.isNone:
    return

  if state.isGameStarted:
      initGameSound()
      initBikeSound()

  var startState = state.gameStartState.get
  startState.gameStartFrame += 1
  if startState.gameStartFrame < 0:
    # do not delay level load, skip first game frame
    return 

  if readyGoBitmapTable.isNil:
    readyGoBitmapTable = getOrLoadBitmapTable(BitmapTableId.ReadyGo)
    titleFont = getOrLoadFont(FontId.M6X11)
  
  if startState.readyGoFrame >= readyGoBitmapTable.frameCount - 1:
    state.gameStartState = none(GameStartState)
    return

  let frameRepeat = if state.isGameStarted: 2 else: 4

  if startState.readyGoFrame == readyEndFrameIdx and not state.isGameStarted:
    # "Ready?" should be displayed until the game starts
    # While idle, perform preloading
    runPreloader(getElapsedSeconds() + 0.50.Seconds)
    return

  if startState.gameStartFrame mod frameRepeat == 0 and startState.readyGoFrame < readyGoBitmapTable.frameCount - 1:
    startState.readyGoFrame += 1
    
proc drawGameStartOverlay*(state: GameStartState) =
  if state.gameStartFrame < 0:
    return
  let name = state.levelName
  let (textW, textH) = titleFont.getTextSize(name)
  let textRect = Rect(
    x: 18,
    y: 216,
    width: textW.int32,
    height: textH.int32
  )
  textRect.inset(-4,-4, -4, -2).fillRoundRect(
    radius=4,
    color=kColorBlack
  )
  gfx.setFont(titleFont)
  gfx.setDrawMode(kDrawModeFillWhite)
  gfx.drawText(name, textRect.x, textRect.y)
  gfx.setDrawMode(kDrawModeCopy)
  
  readyGoBitmapTable.getBitmap(state.readyGoFrame).draw(113, 4, kBitmapUnflipped)
