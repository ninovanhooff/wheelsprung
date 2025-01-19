import std/random
import playdate/api

proc playVariation*(player: SamplePlayer) =
  player.play(1, rand(0.9f .. 1.1f))

proc play*(player: SamplePlayer) {.inline.} =
  player.play(1, 1.0f)