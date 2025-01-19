@echo off

REM Store the script's directory to a variable
set "SCRIPT_DIR=%~dp0"

REM Remove the directory temp.pdx inside SCRIPT_DIR
rmdir /s /q "%SCRIPT_DIR%temp.pdx"

echo Script directory: %SCRIPT_DIR%

REM Create an empty file called temp.lua in the script directory
copy nul "%SCRIPT_DIR%temp.lua" >nul

echo Converting assets...

pdc -v -k -m temp.lua "%SCRIPT_DIR%\"

REM Remove the temp.lua file
del "%SCRIPT_DIR%temp.lua"

echo DONE
echo Assets can be found in the temp.pdx directory

pause