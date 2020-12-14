-- local xmldoc = require("lib/xmldoc")
local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local racetrans = require "lookup//localisation".race

local SystemText = dl.getfile(nil, 'SystemText.atb')
local SystemText = parse_al.parse(SystemText)

local files = {
  'PlayerRaceType.atb',
  'PlayerAssignType.atb',
  'PlayerIdentityType.atb',
  'PlayerBloodType.atb',
  'PlayerGenusType.atb',
}

for k1, FileName in pairs(files) do

  local text = dl.getfile(nil, FileName)
  local obj = parse_al.parse(text)

  for k, v in pairs(obj) do
    if k == 'header' or k == 'type' then else
      if v[2]['v'] > 0 and v[3]['v'] > 0 then
          local originalText = SystemText[v[3]['v']+1][2]['v']
          print(originalText .. " = " .. (racetrans(originalText) or originalText))
      end
    end
  end
  print("\n")
end