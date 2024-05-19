--import "CoreLibs/graphics"

local message = "If you see this message, main.lua is executed.\nThis means the Nim code is \n probably not present in the pdx"
print(message)

function playdate.update()
    playdate.graphics.drawText(message, 10,10)
end
