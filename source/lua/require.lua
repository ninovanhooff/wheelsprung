local playdate <const> = playdate
local run <const> = playdate.file.run

local requiredPaths <const> = {}

function require(sourcePath)
  if requiredPaths[sourcePath] then
      print("SKIP: Already required", sourcePath)
      return
  end
  print("RUN " .. sourcePath)
  requiredPaths[sourcePath] = true
  return run(sourcePath)
end