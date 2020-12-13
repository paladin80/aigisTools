-- curl.lua library
-- v1.0
-- author: lzlis

--ShinyAfro CFG stuff Start
local config = require "lookup//config"
curltimeout = config['Automatic download timeout'] or 30
if not config['CURL Download Stream'] then curlsuffix = ' >nul 2>&1' else curlsuffix = " 1>&2" end
--ShinyAfro End

local curlpath = [[curl]]

local verbose = config['CURL Printouts'] --originally set to true.

local function execute(...)
  local command = curlpath
  for i = 1, select('#', ...) do
    command = command .. " " .. tostring(select(i, ...))
  end
  if verbose then
    io.stderr:write(command .. "\n")
  end
  assert(os.execute("cmd /C timeout /T "..curltimeout..curlsuffix))
  assert(os.execute("cmd /C " .. command .. curlsuffix))
end

return {execute = execute}
