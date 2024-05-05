import level_meta/level_data
import navigation/screen

const LEVEL_SELECT_VISIBLE_ROWS* = 5


type LevelSelectScreen* = ref object of Screen
  levelMetas*: seq[LevelMeta]
  selectedIndex*: int
  scrollPosition*: int