print("===== MAIN.LUA start =====")

-- -- IMPORT:
-- -- Panels is included as a submodule in this repo
-- -- if you don't see any files in libraries/panels  
-- -- you may need to initialize the submodule
-- import "libraries/panels/Panels"

-- -- CREDITS:
-- -- edit the table inside `credits.lua`
-- -- to create your game credits
-- import "gameCredits.lua"
-- Panels.credits = gameCredits

-- -- COMIC DATA:
-- -- add data to the table in this file to create your comic
-- -- Nino: nope, we are using the example data below
-- -- import "myComicData.lua"
-- -- comicData = myComicData


-- -- EXAMPLES:
-- -- uncomment this file to have the example data used in the `start()` command
-- -- look in the `examples` folder for the data files
-- import "examples/comicData.lua"

-- print("comicData", comicData)

-- -- SETTINGS:
-- -- change any settings before calling `start()`
-- Panels.Settings.showMenuOnLaunch = true


-- -- START:
-- -- send the data table of your comic (or an example above) to the `start()` command
-- -- Panels.start(comicData)

-- function StartPanelsExample(finishCallback)
--     print("lua: StartPanelsExample", comicData, finishCallback)
--     Panels.startCutscene(comicData, finishCallback)
-- end

-- function EndPanelsExample()
--     print("lua: EndPanelsExample")
--     Panels.haltCutscene()
-- end

-- function UpdatePanels()
--     Panels.update()
-- end
-- playdate.setCollectsGarbage(false)
-- playdate.stop()

function playdate.update()
    print("lua: playdate.update")
end

-- local menu = playdate.getSystemMenu()

-- local menuItem, error = menu:addMenuItem("LuaItem", function()
--     print("LuaItem selected")
-- end)

function LuaAddMenuItemWorkaround(name, f)
	local menu = playdate.getSystemMenu()
	local menuItem, error = menu:addMenuItem(name, f)
end

-- playdate.stop()

print("===== MAIN.LUA end =====")