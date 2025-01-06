print("===== MAIN.LUA start =====")

-- IMPORT:
-- Panels is included as a submodule in this repo
-- if you don't see any files in libraries/panels  
-- you may need to initialize the submodule
import "libraries/panels/Panels"
-- SETTINGS:
-- load common Panels settings
-- Probably, not other calls to Panels.Settings are needed
import "comicData/panelsSettings"

-- COMIC DATA:
-- add data to the table in this file to create your comic
import "comicData/intro.lua"

function StartIntroCutscene(finishCallback)
    print("StartIntroCutscene", IntroCutscene, finishCallback)
    Panels.startCutscene(IntroCutscene, finishCallback)
end

function UpdatePanels()
    -- workaround for inputHandlers not called when C code is running
    -- https://devforum.play.date/t/lua-inputhandlers-not-called-when-both-c-updatecallback-is-defined/20745
    local crankChange, acceleratedChange = playdate.getCrankChange()
    if crankChange ~= 0 then
        Panels.cranked(crankChange, acceleratedChange)
    end
    Panels.update()
end

-- not sure if these actually do anything
-- when the main loop is not defined in Lua
playdate.setCollectsGarbage(false)
playdate.stop()
print("===== MAIN.LUA end =====")