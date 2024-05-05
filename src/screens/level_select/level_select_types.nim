import level_meta/level_data
import navigation/screen
import common/save_slot_types
export save_slot_types

const 
  LEVEL_SELECT_VISIBLE_ROWS*: int = 6


type 
  LevelRow* = ref object
    levelMeta*: LevelMeta
    progress*: LevelProgress
    
  LevelSelectScreen* = ref object of Screen
    levelRows*: seq[LevelRow]
    selectedIndex*: int
    scrollPosition*: float32
    scrollTarget*: float32