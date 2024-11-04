import navigation/screen

type
  LeaderboardScore* = ref object of RootObj
    rank*: uint32
    player*: string
    timeString*: string
    isCurrentPlayer*: bool
  Leaderboard* = ref object of RootObj
    boardId*: string
    boardName*: string
    scores*: seq[LeaderboardScore]
  #   lastUpdated*: uint32
  LeaderboardsScreen* = ref object of Screen
    leaderboards*: seq[Leaderboard]
    currentLeaderboardIdx*: int
    initialBoardId*: string
    isDirty*: bool