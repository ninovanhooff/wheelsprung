print("===== MAIN.LUA start =====")

import "lua/require"

function StartIntroCutscene(finishCallback)
    require("lua/panelsLoader")
    print("StartIntroCutscene")
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