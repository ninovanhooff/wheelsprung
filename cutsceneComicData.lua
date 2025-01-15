-- all the data for your comic goes into this table
-- you can split it up into multiple files to make it easier to manage 

import "intro.lua"
import "ending.lua"

function table.merge(t1, t2)
	for _,v in ipairs(t2) do
		table.insert(t1, v)
	end 

	return t1
end

cutsceneComicData = table.merge(IntroCutscene, EndingCutscene)