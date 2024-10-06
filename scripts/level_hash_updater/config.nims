--path:"../../src"
--styleCheck:hint

const gameResultSalt = getEnv("WHEELSPRUNG_GAME_RESULT_SALT")
switch("define", "gameResultSalt=" & gameResultSalt)

const levelSalt = getEnv("WHEELSPRUNG_LEVEL_SALT")
switch("define", "levelSalt=" & levelSalt)
