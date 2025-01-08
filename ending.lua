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
                { image = "Ending/B/house.png",     parallax = 0.6 },
                { image = "Ending/B/flip.png",  parallax = 0.3 },
            }
        }
    }
}

-- A cutscene must be a ComicData object, which is a table of sequences.
EndingCutscene = {
    Ending
}
