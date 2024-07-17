-- this is the data for one SEQUENCE

example5 = { 
    title = "Ex 5: Audio",
    -- this audio plays for the entire SEQUENCE (during all panels)
    audio = {file = "examples/sequenceLoop", loop = true },
	panels = {
		{ -- panel 1
			layers = {
				{ text = "Example 5", x = 50, y = 100 },
				{ text = "Audio", x = 50, y = 130 }
			}
		},
        { -- panel 2
            -- this audio plays for this PANEL only
            -- panel audio fades in and out slightly
            -- note that this loop doesn't necessarily sync up with the sequence loop
            -- pay attention to how your sounds overlap and interact
            audio = {file = "examples/panelLoop.wav", loop = true },
            layers = {
                { image = "examples/ex5/piano.png", parallax = 0.2 },
                { image = "examples/ex5/hand.png", parallax = 0.1, y = 130, 
                    -- this sound effect is triggered when the animation is triggered
                    -- (at 40% panel scroll)
                    animate = {y = 0, scrollTrigger = 0.4, audio = { file = "examples/clonk.wav" } }
                }
            }
        },
        { -- panel 4
			layers = {
				{ text = "*THE END*", x = 50, y = 100 }
			}
		}
    }
}