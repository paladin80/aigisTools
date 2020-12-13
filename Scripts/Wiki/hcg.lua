-- Hentai Content-Graphics
-- v1.0
-- author: ShinyAfro

local nametrans = require "lookup//localisation".name
local config = require "lookup//config"
local out = config['Unit directory']
local working = config['working directory']
local dumploc = config['dump directory']

local function parse(id, mode)
  local uid = string.format("%03d", id)
  local dl = require("lib/download")
  local file = require("lib/file")
  local filelist = dl.getlist_raw(config['1fp32igvpoxnb521p9dqypak5cal0xv0'])
  if filelist:match('HarlemCG_'..uid..'_%d.png') then
    local out
    if config['Named directories'] and config['Named unit directory'] then out = config['Named unit directory'] end
    if mode and mode['dump'] and not file.dir_exists(config['dump directory']) then
      file.make_dir(config['dump directory']) out = dumploc 
	elseif mode and mode['dump'] then
	  out = dumploc 
	else
      out = out .. (nametrans(id) or string.format("%03d", id))
      if not file.dir_exists(out) then file.make_dir(out) end
      out = out..'//HCG'
      if not file.dir_exists(out) then file.make_dir(out) end
	end
    for fname in filelist:gmatch('HarlemCG_'..uid..'_%d.png') do
      local text = dl.getfile(nil, fname)
      local h = assert(io.open(out .. "\\" .. fname, 'wb'))
      assert(h:write(text))
      assert(h:close())
    end
  end
end

return {
  parse = parse,
}
