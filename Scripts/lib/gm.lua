-- gm.lua library
-- v1.0
-- author: lzlis

--Shiny CFG stuff
local config = require "lookup//config"
--Shiny end

local gmpath =
-- replace the part of the following line between the [[ ]] with
-- the path to your copy of GraphicsMagick (or just gm if it is
-- on your system path). (Make sure to use Q8 version.)
[[gm]]

if gmpath:match(" ") then
  gmpath = "\"" .. gmpath .. "\""
end

return {
  execute = function(args)
    local command = gmpath .. " " .. args
	if config['GM Printouts'] then
      print(command)
	end
    return assert(os.execute(command))
  end,
  path = gmpath,
}
