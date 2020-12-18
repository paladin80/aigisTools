-- mission/list.lua
-- outputs list of known missions (aka quest series)
-- author: Achura

local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local loc = require "lookup//localisation"

local mission_types = {
  "Emergency",
  "Challenge",
  "Daily",
  "DevilAdvent",
  "Harlem",
  "Raid",
  "Reproduce",
  "Story",
  "Subjugation",
  "Assault",
  "Tutorial",
  "Tower",
  "DailyReproduce"
}

local incentive_types = {
  [1] = "E.Farming",
  [2] = "E.StarRush",
  [3] = "E.Collection",
}

local function get_mission_type(mission_id)
  for _, mtype in ipairs(mission_types) do
    local qlname = mtype .. "MissionConfig.atb"
    if dl.listhasfile(nil, qlname) then
      local qlist = dl.getfile(nil, qlname)
      qlist = parse_al.parse(qlist)
      qlist = parse_al.totable(qlist)
      for _, entry in ipairs(qlist) do
        if entry.MissionID == mission_id then
          return mtype
        end
      end
    end
  end
  return nil
end

local function dump_list(argument)
  local full_dump = false
  if argument == 'all' then full_dump = true end

  local f = io.open('out/missions/mission_series.txt', 'w')
  assert(f:write(string.format("%7s\t%12s\t%s\t%s\n", "Serie", "Type", "Name", "Translated")))

  for _, mtype in ipairs(mission_types) do
    local qlname = mtype .. "MissionConfig.atb"
    if dl.listhasfile(nil, qlname) then
      local qlist = dl.getfile(nil, qlname)
      qlist = parse_al.parse(qlist)
      qlist = parse_al.totable(qlist)
      for _, entry in ipairs(qlist) do
        if full_dump or entry.Enable > 0 then
          local incentive = incentive_types[entry.IncentiveType] or mtype
          local name = entry.Name:gsub(':', '')
          local translated = loc.translate(name)
          name = name .. string.rep(" ", 25 - utf8.len(name))
          assert(f:write(string.format("%7s\t%12s\t%s\t%s\n", entry.MissionID, incentive, name, translated)))
        end
      end
    end
  end
  assert(io.close(f))
  print("mission_series.txt created successfully")
end

return {
  dump_list = dump_list,
  get_mission_type = get_mission_type
}