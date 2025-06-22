{. push raises: [].}
import playdate/api
import std/options
import std/strutils
import navigation/[screen, navigator]
import common/[graphics_types, graphics_utils]
import common/utils
import cache/font_cache
import dialog_types
export dialog_types

const
  dialogCornerRadius: int32 = 10
  buttonCornerRadius: int32 = 4
  dialogY = 10
  titleY = dialogY + 22
  messageY = titleY + 35

let
  dialogRect: Rect = Rect(x: 10, y: dialogY, width: 380, height: 240) ## lower corners outside the screen
  buttonRect: Rect = Rect(x: 150, y: 190, width: 100, height: 32)
  messageBounds: Rect = Rect(x: 50, y: messageY, width: 300, height: buttonRect.y - messageY - 10)  
    ## message will be centered in this rectangle

proc drawDialog*(screen: DialogScreen) =
  # dialog background
  fillRoundRect(dialogRect, dialogCornerRadius, kColorWhite)
  drawRoundRect(dialogRect, dialogCornerRadius, 2, kColorBlack)
  # button background
  fillRoundRect(buttonRect, buttonCornerRadius, kColorBlack)
  # text
  gfx.setFont(getOrLoadFont(FontId.Roobert11Medium))
  gfx.drawTextAligned(screen.title.toUpper(), 200, titleY)
  let messageRectResult = getTextSizeInRect(screen.message, messageBounds)
  let boundsInsetY: int32 = (messageBounds.height - messageRectResult.height.int32) div 2
  drawTextInRect(
    text = screen.message, 
    rect = messageBounds.inset(x = 0, y = boundsInsetY),
    )
  gfx.setDrawMode(kDrawModeFillWhite)
  gfx.drawTextAligned(screen.confirmButtonText, 200, buttonRect.y + 8)

method resume*(screen: DialogScreen): bool =
  screen.drawDialog()
  return true

method update*(screen: DialogScreen): int =
  let buttonState = playdate.system.getButtonState()
  if buttonState.pushed.anyButton({kButtonA, kButtonB}):
    popScreen()

method getRestoreState*(screen: DialogScreen): Option[ScreenRestoreState] =
  return none(ScreenRestoreState)
