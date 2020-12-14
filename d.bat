@ECHO off
SETLOCAL
SET HTTPS_PROXY=
set PATH=./Utilities/cURL/bin;./Utilities/GraphicsMagick;./Utilities/pngout;%PATH%
set LUA_PATH=%LUA_PATH%;./Scripts/?.lua
"Utilities\Lua 5.3"\lua Scripts\%*
