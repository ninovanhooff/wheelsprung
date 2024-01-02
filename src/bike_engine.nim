import playdate/api

const
    idleRpm = 1300.0f

var 
    samplePlayer: SamplePlayer

    curRpm: float = idleRpm

proc lerp*(initial: float, target: float, factor: float): float =
    result = (initial * (1.0 - factor)) + (target * factor)

proc initBikeEngine*()=
    try:
        samplePlayer = playdate.sound.newSamplePlayer("/audio/engine/1300rpm_idle_audacity")
        samplePlayer.play(0, 1.0f)
    except:
        playdate.system.logToConsole(getCurrentExceptionMsg())

proc updateBikeEngine*(throttle: bool, wheelAngularVelocity: float) =
    let targetRpm = 
        if throttle: 
            1300.0f + (wheelAngularVelocity * 100.0f) 
        else: 
            idleRpm
    
    curRpm = lerp(curRpm, targetRpm, 0.1f)
    playdate.system.logToConsole("RPM: " & $curRpm)
    samplePlayer.setRate(curRpm / idleRpm)
