type
  BoardId* = string
  ScoreboardChangedCallback* = proc (boardId: BoardId) {.raises: [].}

const LEADERBOARD_BOARD_ID* = "leaderboard"
