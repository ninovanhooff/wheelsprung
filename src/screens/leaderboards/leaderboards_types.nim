import navigation/screen

type
  LeaderboardScore* = ref object of RootObj
    rank*: uint32
    player*: string
    timeString*: string
    isCurrentPlayer*: bool
  LeaderboardPage* = ref object of RootObj
    boardId*: string
    boardName*: string
    scores*: seq[LeaderboardScore]
  #   lastUpdated*: uint32
  LeaderboardsScreen* = ref object of Screen
    pages*: seq[LeaderboardPage]
    currentPageIdx*: int
    initialBoardId*: string