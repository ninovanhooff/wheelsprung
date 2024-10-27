import playdate/api
import navigation/screen

type
  LeaderboardPage* = ref object of RootObj
    boardID*: string
    boardName*: string
    scores*: seq[PDScore]
    lastUpdated*: uint32
  LeaderboardsScreen* = ref object of Screen
    currentPageIdx*: int32