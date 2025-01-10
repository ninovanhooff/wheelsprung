Ending = { -- Sequence 2
    title = "Ending",
    panels = { -- a list of PANELS for Sequence 2
        {     -- Panel 1
            layers = {
                { image = "Ending/A/house.png",     parallax = 0.6 },
                { image = "Ending/A/flip.png",  parallax = 0.3 },
                { image = "Ending/A/speech.png", parallax = 0.2 },
                {
                    text = "*    Wow, that was delicious!*",
                    x = 295, y = 15,
                    rect =  {width = 70, height = 123},
                    parallax = 0.2
                },
            }
        },

        { -- Panel 2
        layers = {
            { image = "Ending/B/tree.png",     parallax = 0.7 },
            { image = "Ending/B/flip.png",     parallax = 0.5, x = -20 },
            { imageTable = "Ending/B/smell.gif",  loop = true, parallax = 0.3 },
    
        }
    },

        { -- Panel 3
            layers = {
                { image = "Ending/C/house.png",     parallax = 0.6 },
                { image = "Ending/C/flip.png",  parallax = 0.4},
                { image = "Ending/C/speech.png",  parallax = 0.3},
                {
                    text = "*    Mmmm \r  What's that tasty \r   smell*",
                    x = 285, y = 85,
                    rect =  {width = 80, height = 123},
                    parallax = 0.3
                },
            }
        },

        { -- Panel 4
        layers = {
            { image = "Ending/D/kitchen.png",     parallax = 0.6 },
            { image = "Ending/D/acorn.png",     parallax = 0.5 },
            { image = "Ending/D/window.png",  parallax = 0.3 },
        }
    },
        { -- Panel 5
        layers = {
            { image = "Ending/E/background.png",     parallax = 0.6 },
            { image = "Ending/E/flip.png",  parallax = 0.4},
            { image = "Ending/E/speech.png",  parallax = 0.4},
            { image = "Ending/E/acorn.png",  parallax = 0.3},
            {
                text = "*        A DELICIOUS \r  ACORN!*",
                x = 287, y = 90,
                rect =  {width = 80, height = 123},
                parallax = 0.4
            },
        }
    },
        { -- Panel 6
        layers = {
            { image = "Ending/F/flip.png",  parallax = 0.3},
            {
                text = "*Maybe there are more I missed?*",
                x = 280, y = 5,
                rect =  {width = 110, height = 123},
                parallax = 0.3
            },
        }
    },
        { -- Panel 7
        layers = {
            { image = "Ending/G/background.png",     parallax = 0.6 },
            { image = "Ending/G/flip.png",  parallax = 0.4},
            { image = "Ending/G/stars.png",     parallax = 0.3 },
            { image = "Ending/G/speech.png",  parallax = 0.3},
            {
                text = "*Let’s ride again and find acorns!*",
                x = 270, y = 15,
                rect =  {width = 100, height = 123},
                parallax = 0.3
            },
        }
    }


    }
}

-- A cutscene must be a ComicData object, which is a table of sequences.
EndingCutscene = {
    Ending
}
