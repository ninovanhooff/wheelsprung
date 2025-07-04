import playdate/api
import chipmunk7
import common/utils
import screens/game/game_types
import cache/sound_cache

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
        idlePlayer = getOrLoadSamplePlayer(SampleId.BikeEngineIdle)
        throttlePlayer = getOrLoadSamplePlayer(SampleId.BikeEngineThrottle)
        currentPlayer = idlePlayer
        # currentPlayer.play(0, 1.0f)
        currentPlayer.volume = maxVolume
        isInitialized = true
    except:
        print(getCurrentExceptionMsg())

proc updateBikeEngine*(state: GameState) =
    if not state.isGameStarted: return
    initBikeEngine()
        
    let throttle = state.isThrottlePressed
    let wheelForwardAngularVelocity = state.rearWheel.angularVelocity * state.driveDirection
    let targetRpm = 
        if throttle: 
            idleRpm + (wheelForwardAngularVelocity * 50.0f) 
        else: 
            idleRpm

    curRpm = lerp(curRpm, targetRpm, 0.1f)
    targetPlayer = if throttle: throttlePlayer else: idlePlayer
    if currentPlayer != targetPlayer:
        fadeoutPlayer = currentPlayer
        currentPlayer = targetPlayer
        currentPlayer.volume = maxVolume
        
    if currentPlayer.isPlaying == false:
        # after a quick level restart, the player might not be playing https://trello.com/c/xtPKx1cH
        currentPlayer.play(0, 1.0f) 

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

    # print("currentPlayer: ", currentPlayer.repr, "isPlaying:", currentPlayer.isPlaying,  "isThrottlePlayer", currentPlayer == throttlePlayer ," curRpm: ", curRpm, " targetRpm: ", targetRpm, " throttle: ", throttle)

proc pauseBikeEngine*()=
    if not isInitialized: return
    
    currentPlayer.stop()
    if fadeoutPlayer != nil:
        fadeoutPlayer.stop()
