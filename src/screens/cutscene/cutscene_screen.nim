{.push raises: [].}
import playdate/api
import common/utils
import navigation/[screen, navigator]
import screens/screen_types
import cutscene_types
import level_meta/level_data

var
  activeCutsceneId: CutsceneId = CutsceneId.Intro
    ## We need to keep this as a variable because we cannot reference the screen in the callback (cdecl)

proc finish() =
  print "Finishing cutscene", activeCutsceneId
  case activeCutsceneId:
    of CutsceneId.Intro:
      let firstLevelPath = getFirstOfficialLevelMeta().path
      replaceScreen(newGameScreen(levelPath = firstLevelPath))
    of CutsceneId.Ending:
      popScreen()

proc finishCallback(state: LuaStatePtr): cint {.cdecl, raises: [].} =
  finish()
  return 0

proc init(screen: CutSceneScreen) =
  try:
    let luaFunctionName = case screen.cutsceneId:
      of CutsceneId.Intro:
        "StartIntroCutscene"
      of CutsceneId.Ending:
        "StartEndingCutscene"
    playdate.lua.pushFunction(finishCallback)
    markStartTime()
    playdate.lua.callFunction(luaFunctionName, 1) # pass 1 arg: finishCallback
    printT("Cutscene init")
    screen.isInitialized = true
    activeCutsceneId = screen.cutsceneId
  except:
    print "Error initializing cutscene", getCurrentExceptionMsg()

method resume*(screen: CutSceneScreen): bool =
  playdate.display.setRefreshRate(30)

  # add menu item to skip the story
  discard playdate.system.addMenuItem("Skip Story", proc(menuItem: PDMenuItemButton) =
    finish()
  )

  return true

method pause*(screen: CutSceneScreen) =
  playdate.display.setRefreshRate(NOMINAL_FRAME_RATE)

method destroy*(screen: CutSceneScreen) =
  screen.pause()

method update*(screen: CutSceneScreen): int =
  if not screen.isInitialized:
    screen.init()

  let buttonState = playdate.system.getButtonState()
  if kButtonB in buttonState.pushed:
    # We might want to call Panels.haltCutscene() if bg audio is still playing
    # if not, unloading the cutscene is a waste of time since we have ample memory
    finish()
    return 0

  try:
    playdate.lua.callFunction("UpdatePanels", 0)
  except:
    print "Error updating cutscene", getCurrentExceptionMsg()
  
  return 1
