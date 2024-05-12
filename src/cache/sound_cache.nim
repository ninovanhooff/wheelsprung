{.push raises: [].}
import tables
import playdate/api

template snd*: untyped = playdate.sound


type 
  # a table mapping image path to SamplePlayer
  SamplePlayerCache = TableRef[string, AudioSample]

# global singleton
let sampleplayerCache = SamplePlayerCache()

proc getOrLoadSample(path: string): AudioSample =
  try:
    return sampleplayerCache.mgetOrPut(path, snd.newAudioSample(path))
  except IOError:
    playdate.system.error("FATAL: " & getCurrentExceptionMsg())

proc getOrLoadSamplePlayer*(path: string): SamplePlayer =
  result = snd.newSamplePlayer()
  result.sample= getOrLoadSample(path)

# todo use in game screen