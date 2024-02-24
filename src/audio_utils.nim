import std/random
import playdate/api

proc playVariation*(player: SamplePlayer) =
  player.play(1, rand(0.9f .. 1.1f))