import playdate/api

type
  BoardId* = string
  ScoreboardChangedCallback* = proc (boardId: BoardId) {.raises: [].}
  ScoreboardStateKind* = enum
    Loading
    Loaded
    Error
  ScoreboardState* = object of RootObj
    boardId*: BoardId

    case kind*: ScoreboardStateKind
    of Loading:
      discard
    of Loaded:
      scores*: PDScoresList
    of Error:
      discard
    

const LEADERBOARD_BOARD_ID* = "leaderboard"
