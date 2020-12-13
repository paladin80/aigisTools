@ECHO off
chcp 65001
SET PATH=%~dp0Utilities\Lua 5.3;%~dp0Utilities\cURL\bin;%~dp0Utilities\GraphicsMagick;%~dp0Utilities\Pngout;%PATH%
SET LUA_PATH=%~dp0Scripts\?.lua
SET LUA_PATH_5_3=%~dp0Scripts\?.lua

cmd