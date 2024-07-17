
example3a = { -- sequence 1
	title = "Ex 3A: Image Transition by Scroll",
	panels = {
		{ -- panel 1
			layers = {
				{ text = "Example 3", x = 50, y = 100 },
				{ text = "Images transition as you scroll", x = 50, y = 130 }
			}
		},
		{ -- panel 2 
			transitionOffset = -0.025,
			layers = {
				{ image = "examples/ex3/1-bg.png", parallax = 1 },

				-- layers with multiple images transition automatically as the panel scrolls
				-- man image (2 versions)
				{ images = { "examples/ex3/1-manA.png", "examples/ex3/1-manB.png"}, x = 10, parallax = 0.2 },
				-- speech bubble (2 versions)
				{ images = { "examples/ex3/1-bubbleA.png","examples/ex3/1-bubbleB.png"},  parallax = 0.1 },

			},
		},
		{ -- panel 3 
			layers = {
				{ image = "examples/ex3/1-bg.png", parallax = 1 },
				-- man image (2 versions)
				{ images = {"examples/ex3/2-manA.png", "examples/ex3/2-manB.png"} },
				-- speech bubble (2 versions)
				{ images = {"examples/ex3/2-bubbleA.png","examples/ex3/2-bubbleB.png"} },
			},

		},
		{ -- panel 
			layers = {
				{ text = "Continue...", x = 50, y = 100 }
			}
		},
	}
}


example3b = { -- sequence 1
	title = "Ex 3B: Image Transition by Button Press",
	scrollType = Panels.ScrollType.AUTO,
	advanceControl = Panels.Input.A,
	panels = {
		{ -- panel 1
			layers = {
				{ text = "Example 3B", x = 50, y = 100 },
				{ text = "Advance Images with *A button*", x = 50, y = 130 }
			}
		},
		{ -- panel 2 
			-- panel advances after third press of A button
			advanceControlSequence = {Panels.Input.A, Panels.Input.A, Panels.Input.A},
			layers = {
				{ image = "examples/ex3/1-bg.png", parallax = 1 },
				-- list an `advanceControl` to transition multiple images with a button press
				-- man image (2 versions)
				{ images = {"examples/ex3/1-manA.png", "examples/ex3/1-manB.png"}, 
					x = 10, parallax = 0.2, advanceControl = Panels.Input.A 
				},
				-- speech bubble (2 versions)
				{ images = {"examples/ex3/1-bubbleB.png", "examples/ex3/1-bubbleA.png","examples/ex3/1-bubbleB.png"},
					parallax = 0.1, advanceControl = Panels.Input.A 
				},
			},
		},
		{ -- panel 3 
			-- panel advances with delay after A button
			advanceDelay = 700,
			layers = {
				{ image = "examples/ex3/1-bg.png", parallax = 1 },
				-- man image (2 versions)
				{ images = {"examples/ex3/2-manA.png", "examples/ex3/2-manB.png"}, 
					parallax = 0.2, advanceControl = Panels.Input.A 
				},
				-- speech bubble (2 versions)
				{ images = {"examples/ex3/2-bubbleA.png","examples/ex3/2-bubbleB.png"}, 
					parallax = 0.1, advanceControl = Panels.Input.A 
				},
			},

		},
		{ -- panel 
			layers = {
				{ text = "Continue...", x = 50, y = 100 }
			}
		},
	}
}
