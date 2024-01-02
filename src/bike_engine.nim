import playdate/api


var samplePlayer: SamplePlayer


proc initBikeEngine*()=
    try:
        samplePlayer = playdate.sound.newSamplePlayer("/audio/engine/1300rpm_idle_audacity")
        samplePlayer.play(0, 1.0f)
    except:
        playdate.system.logToConsole(getCurrentExceptionMsg())
