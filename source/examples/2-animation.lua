-- this is the data for one SEQUENCE
example2a = { -- sequence 1
	title = "Ex 2A: Scroll Animation",
	axis = Panels.ScrollAxis.VERTICAL,
	panels = {
		{ -- panel 1
			layers = {
				{ text = "Example 2A", x = 50, y = 100 },
				{ text = "Animate by *scroll position*", x = 50, y = 130 }
			}
		},
		{ -- panel 2 
			layers = {
				{ image = "examples/ex2/arm-1.png", x = -550, y = 10,
					-- animate this layer from x:-550 to x:-20 based on the panel scroll position
					animate = { x = -20 } 
				},
				{ image = "examples/ex2/arm-2.png", x = 400, y = 100,
					animate = { x = -120 }
				}
			}
		},
		{ -- panel 3 
			layers = {
				{ text = "Continue...", x = 50, y = 100 }
			}
		}

	}
}

-- this is the data for another SEQUENCE
example2b = { -- sequence 2
	title = "Ex 2B: Button Animation",
	scrollType = Panels.ScrollType.AUTO,
	axis = Panels.ScrollAxis.VERTICAL,
	advanceControl = Panels.Input.A,
	panels = {
		{ -- panel 1
			layers = {
				{ text = "Example 2B", x = 50, y = 100 },
				{ text = "Animate with *A button*", x = 50, y = 130 }
			}
		},
		{ -- panel 2 
			-- this panel advances after the pressing the A button twice
			advanceControlSequence = { Panels.Input.A, Panels.Input.A },
			advanceDelay = 1000, -- wait for the animation to complete before advancing

			layers = {
				{ image = "examples/ex2/arm-1.png", x = -550, y = 10,
					animate = { 
						x = -20, duration = 500, 
						trigger = Panels.Input.A  -- trigger this animation with the A button
					}
				},
				{ image = "examples/ex2/arm-2.png", x = 400, y = 100,
					animate = {
						x = -120, duration = 500, 
						-- A button already triggers first animation
						-- this layer requires TWO presses to trigger the animation
						triggerSequence = {Panels.Input.A, Panels.Input.A} 
					}
				}
			}
		},
		{ -- panel 3 
			layers = {
				{ text = "Continue...", x = 50, y = 100 }
			}
		}

	}
}
