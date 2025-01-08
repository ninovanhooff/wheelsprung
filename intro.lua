Intro = {
    -- Sequence 1
    title = "Introduction",
    panels = { -- a list of PANELS for Sequence 1
        {      -- Panel 1
            layers = {
                { image = "Intro/A/1-shop.png",     parallax = 1 },
                { image = "Intro/A/2-parents.png",  parallax = 0.8 },
                { image = "Intro/A/3-children.png", parallax = 0.6 },
                { image = "Intro/A/4-plant.png",    parallax = 0.1 },
                { 
                    imageTable = "common/buttonRT", 
                    x = 330, y = 100, parallax = 2, 
                    loop = true, startDelay = 1500,
                },
                {
                    text = "Ⓑ: Skip Story",
                    x = 10, y = 200, parallax = 0,
                    background = Panels.Color.WHITE,
                    border = 1, -- does nothing, requires Panels 2.0
                    animate = {
                        trigger = Panels.Input.RIGHT,
                        opacity = 0,
                        duration = 1000,
                        ease = playdate.easingFunctions.outQuint,
                    },
                },
            }
        },
        { -- Panel 2
            frame = { width = 1400 },
            layers = {
                { image = "Intro/B/1-street.png", x = 250, parallax = 0.8 },
                { image = "Intro/B/2-cargo.png",  x = 400, parallax = 0.6 },
                { image = "Intro/B/3-bush.png",   x = 400, parallax = 0.4 },
                { image = "Intro/B/4-tree.png",   x = 400, parallax = 0.3 },
                { image = "Intro/B/5-light.png",  x = 100, parallax = 0.2 },
                { image = "Intro/B/6-light2.png", x = 300, parallax = 0.2 },
            }
        },
        { -- Panel 3
            layers = {
                { image = "Intro/C/1-road.png",  parallax = 0.3 },
                { image = "Intro/C/2-cargo.png", parallax = 0.2 },
                { image = "Intro/C/3-plant.png", parallax = 0.1 },

            }
        },
    }
}

-- A cutscene must be a ComicData object, which is a table of sequences.
IntroCutscene = {
    Intro
}
