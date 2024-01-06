import playdate/api
import utils

const
    idleRpm = 1300.0f
    ## The RPM of the first throttle sound in throttlePlayers. The second throttle sound is 200 RPM higher.
    baseThrottleRpm: float = 1300.0f
    ## The RPM step between throttle sounds. The third throttle sound is 200 RPM higher than the second throttle sound.
    throtthleRpmStep: int = 200

var 
    idlePlayer: SamplePlayer
    curRpm: float = idleRpm
    throttlePlayers: array[3, SamplePlayer]
    currentPlayer: SamplePlayer
    targetPlayer: SamplePlayer

proc initBikeEngine*()=
    try:
        idlePlayer = playdate.sound.newSamplePlayer("/audio/engine/1300rpm_idle")
        throttlePlayers[0] = playdate.sound.newSamplePlayer("/audio/engine/1300rpm_throttle")
        throttlePlayers[1] = playdate.sound.newSamplePlayer("/audio/engine/1500rpm_throttle")
        throttlePlayers[2] = playdate.sound.newSamplePlayer("/audio/engine/1700rpm_throttle")
    except:
        print(getCurrentExceptionMsg())

    currentPlayer = idlePlayer
    currentPlayer.play(0, 1.0f)

proc updateBikeEngine*(throttle: bool, wheelAngularVelocity: float) =
    let targetRpm = 
        if throttle: 
            1300.0f + (wheelAngularVelocity * 100.0f) 
        else: 
            idleRpm

    curRpm = lerp(curRpm, targetRpm, 0.1f)
    print("RPM: " & $curRpm)
    var throttlePlayerIndex: int = (curRpm-baseThrottleRpm).roundToNearest(throtthleRpmStep) div throtthleRpmStep
    throttlePlayerIndex = throttlePlayerIndex.clamp(0, throttlePlayers.high)
    targetPlayer = if throttle: throttlePlayers[throttlePlayerIndex] else: idlePlayer
    if currentPlayer != targetPlayer:
        print("switch from currentPlayer: " & $currentPlayer.repr & " targetPlayer: " & targetPlayer.repr)
        currentPlayer.stop()
        currentPlayer = targetPlayer
        currentPlayer.play(0, 1.0f) # rate is set below
    let playerBaseRpm: float = 
        if throttle: 
            baseThrottleRpm + (throttlePlayerIndex * throtthleRpmStep).float
    else:
        idleRpm
    currentPlayer.rate=curRpm / playerBaseRpm
    print("playerBaseRpm: " & $playerBaseRpm & "throttlePlayerIndex" & $throttlePlayerIndex & " rate: " & $currentPlayer.rate)
