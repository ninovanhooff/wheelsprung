include playdate/build/config

--path:"./src"

# Add a search path for libraries based on OS.
if defined(device):
    switch("passL", "-L" & getCurrentDir() / "lib" / "device")
elif defined(windows):
    switch("passL", "-L" & getCurrentDir() / "lib" / "windows")
elif defined(macosx):
    switch("passL", "-L" & getCurrentDir() / "lib" / "macos")
elif defined(linux):
    switch("passL", "-L" & getCurrentDir() / "lib" / "linux")
else:
    echo "Platform not supported!"
# Link the chipmunk library.
switch("passL", "-lchipmunk")