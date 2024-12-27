Sequence1 = {
    -- Sequence 1
    title = "Chapter 1",
    panels = { -- a list of PANELS for Sequence 1
        {      -- Panel 1
            layers = {
                { image = "Chapter1/A/1-shop.png",     parallax = 1 },
                { image = "Chapter1/A/2-parents.png",  parallax = 0.8 },
                { image = "Chapter1/A/3-children.png", parallax = 0.6 },
                { image = "Chapter1/A/4-plant.png",    parallax = 0.1 },
            }
        },
        { -- Panel 2
            frame = { width = 1400 },
            layers = {
                { image = "Chapter1/B/1-street.png", x = 250, parallax = 0.8 },
                { image = "Chapter1/B/2-cargo.png",  x = 400, parallax = 0.6 },
                { image = "Chapter1/B/3-bush.png",   x = 400, parallax = 0.4 },
                { image = "Chapter1/B/4-tree.png",   x = 400, parallax = 0.3 },
                { image = "Chapter1/B/5-light.png",  x = 100, parallax = 0.2 },
                { image = "Chapter1/B/6-light2.png", x = 300, parallax = 0.2 },
            }
        },
        { -- Panel 3
            layers = {
                { image = "Chapter1/C/1-road.png",  parallax = 0.3 },
                { image = "Chapter1/C/2-cargo.png", parallax = 0.2 },
                { image = "Chapter1/C/3-plant.png", parallax = 0.1 },

            }
        },
    }
}
