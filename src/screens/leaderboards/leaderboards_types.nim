import navigation/screen

type
  LeaderboardStateKind* = enum
    Loading
    Loaded
    Error
  
  LeaderboardScore* = ref object of RootObj
    rank*: uint32
    player*: string
    timeString*: string
    isCurrentPlayer*: bool

  LeaderboardState* = object of RootObj
    case kind*: LeaderboardStateKind
    of Loading:
      discard
    of Loaded:
      scores*: seq[LeaderboardScore]
    of Error:
      discard
  Leaderboard* = ref object of RootObj
    boardId*: string
    boardName*: string
    state*: LeaderboardState
  #   lastUpdated*: uint32
  LeaderboardsScreen* = ref object of Screen
    leaderboards*: seq[Leaderboard]
    currentLeaderboardIdx*: int
    currentLeaderboardPageIdx*: int
    initialBoardId*: string
    isDirty*: bool

const
  LEADERBOARDS_PAGE_SIZE* = 5
