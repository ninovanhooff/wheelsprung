{.push raises: [].}
import playdate/api
import std/sugar
import common/utils
import navigation/[screen, navigator]
import screens/screen_types

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

  playdate.system.logToConsole("cutscene finished. Starting game")
  replaceScreen(newGameScreen(levelPath = "levels/dragster.flatty"))
  
  return 0

proc init(screen: CutSceneScreen) =
  try:
    playdate.lua.pushFunction(finishCallback)
    playdate.lua.callFunction("StartPanelsExample", 1) # pass 1 arg: finishCallback
    screen.isInitialized = true
  except:
    print "Error initializing cutscene"

method resume*(screen: CutSceneScreen): bool =
  playdate.display.setRefreshRate(30)
  playdate.system.logToConsole("Cutscene resumed")
  return true

method update*(screen: CutSceneScreen): int =
  if not screen.isInitialized:
    screen.init()

  try:
    playdate.lua.callFunction("UpdatePanels", 0)
  except:
    print "Error updating cutscene"
  
  return 1
