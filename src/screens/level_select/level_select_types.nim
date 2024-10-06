import playdate/api

import level_meta/level_data
import navigation/screen
import std/options
import common/shared_types
import common/save_slot_types
export save_slot_types

const 
  LEVEL_SELECT_VISIBLE_ROWS*: float32 = 5.5f


type 
  LevelRow* = ref object
    levelMeta*: LevelMeta
    progress*: LevelProgress
    
  LevelSelectScreen* = ref object of Screen
    levelRows*: seq[LevelRow]
    selectedIndex*: int
    scrollPosition*: float32
    scrollTarget*: float32
    levelTheme*: LevelTheme
    firstLockedRowIdx*: Option[int]
    upActivatedAt*: Option[Seconds]
    downActivatedAt*: Option[Seconds]