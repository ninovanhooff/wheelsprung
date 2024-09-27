{.push raises: [].}
import tables
import playdate/api
import common/utils

template snd*: untyped = playdate.sound


type 
  # a table mapping image path to SamplePlayer
  SamplePlayerCache = TableRef[string, AudioSample]

# global singleton
let sampleplayerCache = SamplePlayerCache()

proc getOrLoadSample(path: string): AudioSample =
  try:
    if not sampleplayerCache.hasKey(path):
      markStartTime()
      sampleplayerCache[path] = snd.newAudioSample(path)
      printT("LOAD Sample: ", path)
    
    return sampleplayerCache[path]
  except Exception:
    playdate.system.error("FATAL: " & getCurrentExceptionMsg())

proc getOrLoadSamplePlayer*(path: string): SamplePlayer =
  result = snd.newSamplePlayer()
  result.sample= getOrLoadSample(path)
