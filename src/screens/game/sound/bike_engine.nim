import playdate/api
import chipmunk7
import utils
import screens/game/game_types

const
    idleRpm = 1300.0f
    ## The RPM of the first throttle sound in throttlePlayers. The second throttle sound is 200 RPM higher.
    baseThrottleRpm: float32 = 1700.0f
    maxVolume: float32 = 0.3f
    volumeFadeSpeed: float32 = 0.05f

var 
    isInitialized: bool = false
    idlePlayer: SamplePlayer
    curRpm: float = idleRpm
    throttlePlayer: SamplePlayer
    currentPlayer: SamplePlayer
    targetPlayer: SamplePlayer
    fadeoutPlayer: SamplePlayer

proc initBikeEngine*()=
    if isInitialized: return
    
    try:
        idlePlayer = playdate.sound.newSamplePlayer("/audio/engine/1300rpm_idle")
        throttlePlayer = playdate.sound.newSamplePlayer("/audio/engine/1700rpm_throttle")
        currentPlayer = idlePlayer
        # currentPlayer.play(0, 1.0f)
        currentPlayer.volume = maxVolume
        isInitialized = true
    except:
        print(getCurrentExceptionMsg())

proc updateBikeEngine*(state: GameState) =
    let throttle = state.isThrottlePressed
    let wheelForwardAngularVelocity = state.rearWheel.angularVelocity * state.driveDirection
    let targetRpm = 
        if throttle: 
            idleRpm + (wheelForwardAngularVelocity * 50.0f) 
        else: 
            idleRpm

    curRpm = lerp(curRpm, targetRpm, 0.1f)
    # print("RPM: " & $curRpm)
    targetPlayer = if throttle: throttlePlayer else: idlePlayer
    if currentPlayer != targetPlayer:
        # print("switch from currentPlayer: " & $currentPlayer.repr & " targetPlayer: " & targetPlayer.repr)
        fadeoutPlayer = currentPlayer
        currentPlayer = targetPlayer
        currentPlayer.play(0, 1.0f) 
        currentPlayer.volume = maxVolume

    # rate
    let playerBaseRpm: float = 
        if throttle: 
            baseThrottleRpm
        else:
            idleRpm
    currentPlayer.rate=curRpm / playerBaseRpm

    # volume
    if currentPlayer.volume.left < maxVolume:
        currentPlayer.volume = min(maxVolume, currentPlayer.volume.left + volumeFadeSpeed)
    if fadeoutPlayer != nil:
        if fadeoutPlayer.volume.left > 0.01f:
            fadeoutPlayer.volume = max(0.0f, fadeoutPlayer.volume.left - volumeFadeSpeed)
        else:
            fadeoutPlayer.stop()
            fadeoutPlayer = nil

    # print("playerBaseRpm: " & $playerBaseRpm & "throttlePlayerIndex" & " rate: " & $currentPlayer.rate)
