import playdate/api
import navigation/screen

type
  LeaderboardPage* = ref object of RootObj
    boardId*: string
    boardName*: string
    scores*: seq[PDScore]
  #   lastUpdated*: uint32
  LeaderboardsScreen* = ref object of Screen
    pages*: seq[LeaderboardPage]
    currentPageIdx*: int
    initialBoardId*: string