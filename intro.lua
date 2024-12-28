Intro = {
    -- Sequence 1
    title = "Introduction",
    panels = { -- a list of PANELS for Sequence 1
        {      -- Panel 1
            layers = {
                { image = "cutscenes/Intro/A/1-shop.png",     parallax = 1 },
                { image = "cutscenes/Intro/A/2-parents.png",  parallax = 0.8 },
                { image = "cutscenes/Intro/A/3-children.png", parallax = 0.6 },
                { image = "cutscenes/Intro/A/4-plant.png",    parallax = 0.1 },
            }
        },
        { -- Panel 2
            frame = { width = 1400 },
            layers = {
                { image = "cutscenes/Intro/B/1-street.png", x = 250, parallax = 0.8 },
                { image = "cutscenes/Intro/B/2-cargo.png",  x = 400, parallax = 0.6 },
                { image = "cutscenes/Intro/B/3-bush.png",   x = 400, parallax = 0.4 },
                { image = "cutscenes/Intro/B/4-tree.png",   x = 400, parallax = 0.3 },
                { image = "cutscenes/Intro/B/5-light.png",  x = 100, parallax = 0.2 },
                { image = "cutscenes/Intro/B/6-light2.png", x = 300, parallax = 0.2 },
            }
        },
        { -- Panel 3
            layers = {
                { image = "cutscenes/Intro/C/1-road.png",  parallax = 0.3 },
                { image = "cutscenes/Intro/C/2-cargo.png", parallax = 0.2 },
                { image = "cutscenes/Intro/C/3-plant.png", parallax = 0.1 },

            }
        },
    }
}

-- A cutscene must be a ComicData object, which is a table of sequences.
IntroCutscene = {
    Intro
}
