# Package

version       = "0.2.0"
author        = "Nino van Hooff"
description   = "A motorcross themed physics game for the Playdate handheld."
license       = "MIT"
srcDir        = "src"
bin           = @["wheelsprung"]


# Dependencies

requires "nim >= 2.0.0"
requires "playdate"
requires "murmurhash"
requires "flatty"
# requires "https://github.com/samdze/playdate-nim#main"
# change to chipmunk7 for local development
requires "https://github.com/ninovanhooff/nim-chipmunk-playdate"
include playdate/build/nimble
