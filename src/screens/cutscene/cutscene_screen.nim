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
  let argCount = playdate.lua.getArgCount()
  print(fmt"Nim callback with {argCount} argument(s)")

  try: 
    for i in countup(1, argCount): # Lua indices start from 1...
      let argType = playdate.lua.getArgType(i.cint)

      case argType:
        of kTypeBool:
          let value = playdate.lua.getArgBool(i)
          playdate.system.logToConsole(fmt"Argument {i} is a bool: {value}")
        of kTypeFloat:
          let value = playdate.lua.getArgFloat(i)
          playdate.system.logToConsole(fmt"Argument {i} is a float: {value}")
        of kTypeInt:
          let value = playdate.lua.getArgInt(i)
          playdate.system.logToConsole(fmt"Argument {i} is an int: {value}")
        of kTypeString:
          let value = playdate.lua.getArgString(i)
          playdate.system.logToConsole(fmt"Argument {i} is a string: {value}")
        of kTypeNil:
          let isNil = playdate.lua.argIsNil(i)
          playdate.system.logToConsole(fmt"Argument {i} is nil: {isNil}")
        else:
          playdate.system.logToConsole(fmt"Argument {i} is not a recognized type.")
  except:
    playdate.system.logToConsole(getCurrentExceptionMsg())

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
    playdate.lua.callFunction(luaFunctionName, 1) # pass 1 arg: finishCallback
    screen.isInitialized = true
    activeCutsceneId = screen.cutsceneId
  except:
    print "Error initializing cutscene"

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
