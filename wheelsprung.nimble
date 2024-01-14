# Package

version       = "0.2.0"
author        = "Nino van Hooff"
description   = "A motorcross themed physics game for the Playdate handheld."
license       = "MIT"
srcDir        = "src"
bin           = @["wheelsprung"]


# Dependencies

requires "nim >= 1.6.10"
requires "playdate"
requires "https://github.com/ninovanhooff/nim-chipmunk-playdate"
include playdate/build/nimble
