local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local xmldoc = require("lib/xmldoc")
local xml = require("lib/xml")

local function get_quest_list()
  local text = xmldoc.getfile(nil, "missions")
  local obj = xml.parse(text)
  local da = obj.contents
  local count = #da[1].contents
  local missions = {}
  for i = 1, count do
    local mission = {}
    for _, elt in ipairs(da) do
      mission[elt.tag] = tonumber(elt.contents[i].contents)
    end
    missions[i] = mission
  end

  text = dl.getfile(nil, "QuestNameText.atb")
  local nametext = parse_al.parse(text)
  for _, mission in ipairs(missions) do
    local titleid = mission.QuestTitle
    mission._name = nametext[titleid + 1] and tostring(nametext[titleid + 1][1].v) or "(unknown)"
    if mission._name == nil then
      mission._name = "(nil)"
    elseif #mission._name == 0 then
      mission._name = "(none)"
    end
  end
  return missions
end

return get_quest_list