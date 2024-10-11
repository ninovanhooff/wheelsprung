{.push raises: [].}
import tables
import playdate/api
import common/utils

template snd*: untyped = playdate.sound


type 
  # a table mapping sound path to AudioSample
  AudioSampleCache = TableRef[string, AudioSample]

# global singleton
let audioSampleCache = AudioSampleCache()

proc getOrLoadSample(path: string): AudioSample =
  try:
    if not audioSampleCache.hasKey(path):
      markStartTime()
      audioSampleCache[path] = snd.newAudioSample(path)
      printT("LOAD Sample: ", path)
    
    return audioSampleCache[path]
  except Exception:
    playdate.system.error("FATAL: " & getCurrentExceptionMsg())

proc getOrLoadSamplePlayer*(path: string): SamplePlayer =
  result = snd.newSamplePlayer()
  result.sample= getOrLoadSample(path)
