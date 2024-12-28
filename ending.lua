Ending = { -- Sequence 2
    title = "Ending",
    panels = { -- a list of PANELS for Sequence 2
        {     -- Panel 1
            layers = {
                -- list of layers for panel 1
            }
        },
        { -- Panel 2
            layers = {
                -- list of layers for panel 2
            }
        }
    }
}

-- A cutscene must be a ComicData object, which is a table of sequences.
EndingCutscene = {
    Ending
}
