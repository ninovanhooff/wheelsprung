-- CUSTOM BEHAVIOR FOR PANEL 2 
local gfx <const> = playdate.graphics

local maxPosition = 60
local minPosition = -100
local layerPosition = maxPosition

-- render is called every frame
-- render is responsible for drawing the entire panel
local function renderPanel2(panel, offset)
	local crankChange = playdate.getCrankChange() 
	layerPosition = layerPosition - (crankChange / 10)

	-- constrain layer position
	layerPosition = math.min(maxPosition, layerPosition)
	layerPosition = math.max(minPosition, layerPosition)


	-- draw all the layers in the panel
	for index, layer in ipairs(panel.layers) do
		if layer.name == "head" then
			layer.img:draw(layer.x, layer.y + layerPosition)
		else
			layer.img:draw(layer.x, layer.y)
		end
	end

	-- draw the text
	gfx.drawText("*Crank it up!*", 280, 20)
	
end

-- advance is called every frame
local function advancePanel2()
	if layerPosition <= minPosition then 
		return true -- advance to next panel
	else
		return false -- stay on this panel
	end
end

-- reset is called when the panel leaves the screen
local function resetPanel2()
	-- reset the layer position 
	-- in case the user navigates back to this panel
	layerPosition = maxPosition
end


-- COMIC DATA 

example4 = { 
	-- sequence 1
	title = "Ex 4: Custom Functions",
	scrollType = Panels.ScrollType.AUTO,
	
	panels = {
		{ -- panel 1 (normal panel)
			advanceControl = Panels.Input.A,
			layers = {
				{ text = "Example 4", x = 50, y = 70 },
				{ text = "Custom Functions", x = 50, y = 100 },
				{ text = "*Press A to Start...*", x = 50, y = 130, 
					effect = { type = Panels.Effect.TYPE_ON, duration = 500, delay = 500 }
				}
			}
		},
		{ -- panel 2 (custom render)
			renderFunction = renderPanel2,
			advanceFunction = advancePanel2,
			resetFunction = resetPanel2,
			layers = {
				{ image = "examples/ex4/1-bg.png", },
				{ image = "examples/ex4/1-body.png", },
				{ image = "examples/ex4/1-head.png", name = "head"},
				{ image = "examples/ex4/1-collar.png"},
			},
		},
		{ -- panel 3 (normal panel)
			layers = {
				{ text = "Continue...", x = 50, y = 100,  
					effect = { type = Panels.Effect.TYPE_ON, duration = 300, delay = 500  }
				}
			}
		}

	}
}
