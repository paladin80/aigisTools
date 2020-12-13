@ECHO off
SETLOCAL
SET HTTPS_PROXY=
set PATH=./Utilities/cURL/bin;%PATH%
set LUA_PATH=%LUA_PATH%;./Scripts/?.lua
"Utilities\Lua 5.3"\lua Scripts\%*
