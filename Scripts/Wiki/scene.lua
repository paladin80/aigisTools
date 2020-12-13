local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local file = require("lib/file")
local nametrans = require "lookup//localisation".name
local config = require "lookup//config"
local dumploc = config['dump directory']

local event1 = dl.getfile(nil, "HarlemEventText0.aar")
event1 = parse_al.parse(event1)
local event2 = dl.getfile(nil, "HarlemEventText1.aar")
event2 = parse_al.parse(event2)

--print(names[1]['value']['text'])
--print(event1[1]['name'])
local function parse(id, mode)
  for k, v in pairs(event1) do
    local filename = v['name'] or ''
    local unit_scene = filename:match('[^_]+_([^_]+)_[^_]+.txt')
    local scene_num = filename:match('[^_]+_[^_]+_([^_]+).txt')
	print (scene_num)
  end
end

return{
  parse = parse,}