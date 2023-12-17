include playdate/build/config

const path =
  when defined(windows):
    "path/to/mylib_windows.a"
  elif defined(macosx):
    "lib/macos/libchipmunk.a"
  elif defined(linux):
    "path/to/mylib_linux.a"
switch("passL", path)