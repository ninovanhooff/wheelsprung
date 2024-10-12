-- the Credits screen is accessed from 
-- the Playdate system menu

gameCredits = {

    -- settings for your credits screen
    alignment = Panels.TextAlignment.CENTER,
	autoScroll = false,

    -- the actual credits for your comic
    -- add as many as you like, the page will scroll
    -- you can add images here too
    lines = {
		{ text = "A Very Nice Comic"},
		{ text = "created by *Me*" },
    }
}