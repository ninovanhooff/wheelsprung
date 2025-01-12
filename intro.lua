import "CoreLibs/ui/crankIndicator"

Intro = {
    -- Sequence 1
    title = "Introduction",
    panels = { -- a list of PANELS for Sequence 1
        {      -- Panel 1
            renderFunction = function(panel, offset)
                for i, layer in ipairs(panel.layers) do
                    Panels.renderLayerInPanel(layer, panel, offset)
                end
                if math.abs(offset.x) < 20 then
                    playdate.ui.crankIndicator:draw()
                end
            end,
            layers = {
                { image = "Intro/A/1-shop.png",     parallax = 1 },
                { image = "Intro/A/2-parents.png",  parallax = 0.8 },
                { image = "Intro/A/3-children.png", parallax = 0.6 },
                { image = "Intro/A/4-plant.png",    parallax = 0.1 },
                {
                    text = "Ⓑ: Skip Story",
                    x = 10, y = 200, parallax = 0,
                    background = Panels.Color.WHITE,
                    animate = {
                        scrollTrigger = 0.55,
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

        { -- Panel 4
            layers = {
                { image = "Intro/E/road.png",     parallax = 0.7 },
                { image = "Intro/E/Emily.png",  parallax = 0.6 },
                { image = "Intro/E/Dad.png", parallax = 0.6 },
                { image = "Intro/E/plants.png",    parallax = 0.1 },
                {
                    text = "*This is the best day of \r    my life!*",
                    x = 285, y = 15,
                    rect =  {width = 90, height = 123},
                    parallax = 0.6
                },

            }
        },

        { -- Panel 5
        layers = {
            { image = "Intro/F/House.png",  parallax = 0.6 },
            { image = "Intro/F/Flip.png", parallax = 0.3 },
            {
                text = "*It's going to be \r     the best day\r      of my life.*",
                x = 260, y = 10,
                rect =  {width = 120, height = 123},
                parallax = 0.3
            },

        }
    },

            { -- Panel 6
            layers = {
                { image = "Intro/G/Background.png",  parallax = 0.6 },
                { image = "Intro/G/Emily.png", parallax = 0.3 },
                {
                    text = "*I LOVE NUTS*",
                    x = 305, y = 40,
                    rect =  {width = 50, height = 123},
                    parallax = 0.3
                },

            }
            },


            { -- Panel 7
            layers = {
                { image = "Intro/H/Kitchen.png",  parallax = 0.6 },
                { image = "Intro/H/Emily.png", parallax = 0.3 },

            }
            },
            {      -- Panel 8
            layers = {
                { image = "Intro/I/Bathroom.png",     parallax = 1 },
                { image = "Intro/I/Emily.png",  parallax = 0.8 },
                { image = "Intro/I/Nuts.png", parallax = 0.6 },
                { image = "Intro/I/Towel.png",    parallax = 0.1 },
            }
        },
        {      -- Panel 9
            layers = {
                { image = "Intro/J/Emily.png",     parallax = 0.8 },
                { image = "Intro/J/Window.png",  parallax = 0.7 },
                { image = "Intro/J/Tree.png",    parallax = 0.1 },
            }
        },
        {      -- Panel 10
        layers = {
            { image = "Intro/K/House.png",     parallax = 0.8 },
            { image = "Intro/K/FLip.png",  parallax = 0.75 },
            { image = "Intro/K/Plants.png",    parallax = 0.1 },
        }
    },
    {      -- Panel 11
    layers = {
        { image = "Intro/L/Room.png",     parallax = 0.7 },
        { image = "Intro/L/Nuts.png",     parallax = 0.7 },
        { image = "Intro/L/FLip.png",  parallax = 0.4 },
        { image = "Intro/L/Planet.png",    parallax = 0.1 },
        {
            text = "*   How can \rI get them fast before she’s back?*",
            x = 275, y = 105,
            rect =  {width = 90, height = 123},
            parallax = 0.4
        },
    }
},
    {      -- Panel 12
    layers = {
        { image = "Intro/M/Bike.png",     parallax = 0.7 },
        { image = "Intro/M/Ahh.png",  parallax = 0.6 },
        { image = "Intro/M/FLip.png",  parallax = 0.5 },
        { image = "Intro/M/Rocket.png",    parallax = 0.1 },
    }
    },

    {      -- Panel 13
    layers = {
        { image = "Intro/N/Bike.png",     parallax = 0.7 },
        { image = "Intro/N/Flip.png",  parallax = 0.6 },
        { image = "Intro/N/Stars.png",  parallax = 0.5 },
        { image = "Intro/N/Front.png",    parallax = 0.1 },
    }
    },
    {      -- Panel 14
    layers = {
        { image = "Intro/D/Flip1.png",     parallax = 0.5 },
        {
            text = "*Well, that could actually work!*",
            x = 290, y = 35,
            rect =  {width = 80, height = 123},
            parallax = 0.5
        },

      
    },
},
    {      -- Panel 15
    layers = {
        { image = "Intro/O/Background.png",     parallax = 1 },
        { image = "Intro/O/Flip.png",  parallax = 0.6 },
        { image = "Intro/O/Stars.png",  parallax = 0.8 },
        { image = "Intro/O/Speech.png",    parallax = 0.6 },
        {
            text = "*Yay!*",
            x = 300, y = 15,
            rect =  {width = 90, height = 123},
            parallax = 0.6
        },
    }
    },

    {      -- Panel 16
    frame = { width = 1100 },
    layers = {
        { image = "Intro/P/Background.png", x = 150,     parallax = 0.5 },
        { image = "Intro/P/Flip.png", x = 150, parallax = 0.45 },
        { image = "Intro/P/Nuts.png", x = 150, parallax = 0.4 },
        { image = "Intro/P/Speech.png",   x = 200, parallax = 0.45 },
        {
            text = "*Let's pick up some nuts*",
            x = 360, y = 35,
            rect =  {width = 90, height = 123},
            parallax = 0.45
        },
    }
    },
    }
}

-- A cutscene must be a ComicData object, which is a table of sequences.
IntroCutscene = {
    Intro
}
