import "1-simple-comic.lua"
import "2-animation.lua"
import "3-image-transitions.lua"
import "4-custom-functions.lua"
import "5-audio.lua"


-- this comicData table includes a list of the SEQUENCES 
-- imported from the individual example files
-- you can write this all as one big table, but it gets messy...
comicData = {
	example1,   -- simple comic
	example2a,  -- animation (scroll)
	example2b,  -- animation (button)
	example3a,  -- image transitions (scroll)
	example3b,  -- image transitions (btton)
	example4,   -- custom functions
	example5,   -- audio
}