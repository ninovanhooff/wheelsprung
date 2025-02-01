import playdate/api
import cache/sound_cache
import common/audio_utils

var
  cancelPlayer: SamplePlayer = nil
  confirmPlayer: SamplePlayer = nil
  selectNextPlayer: SamplePlayer = nil
  selectPreviousPlayer: SamplePlayer = nil
  bumperPlayer: SamplePlayer = nil

proc playCancelSound*() =
  if cancelPlayer == nil:
    cancelPlayer = getOrLoadSamplePlayer(SampleId.Cancel)
  cancelPlayer.playVariation()

proc playConfirmSound*() =
  if confirmPlayer == nil:
    confirmPlayer = getOrLoadSamplePlayer(SampleId.Confirm)
  confirmPlayer.playVariation()

proc playSelectNextSound*() =
  if selectNextPlayer == nil:
    selectNextPlayer = getOrLoadSamplePlayer(SampleId.SelectNext)
  # play at constant pitch, since the pitch discerns the direction
  selectNextPlayer.play()

proc playSelectPreviousSound*() =
  if selectPreviousPlayer == nil:
    selectPreviousPlayer = getOrLoadSamplePlayer(SampleId.SelectPrevious)
  # play at constant pitch, since the pitch discerns the direction
  selectPreviousPlayer.play()

proc playBumperSound*() =
  if bumperPlayer == nil:
    bumperPlayer = getOrLoadSamplePlayer(SampleId.Bumper)
  bumperPlayer.playVariation()
