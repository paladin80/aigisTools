local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local handle_mission = require("missions/handle_mission")

local function parse_mission(mtype, series, missions, process_out)
  -- load data files
  local qlname = mtype .. "MissionQuestList.atb"
  if not dl.listhasfile(nil, qlname) then
    print("Quest list file was not found for the mission type " .. mtype)
    return
  end
  local nt = "QuestNameText" .. series .. ".atb"
  if not dl.listhasfile(nil, nt) then
    print("QuestNameText file was not found for the mission " .. series)
    return
  end
  local qlist = dl.getfile(nil, qlname)
  qlist = parse_al.parse(qlist)
  qlist = parse_al.totable(qlist)
  nt = dl.getfile(nil, nt)
  nt = parse_al.parse(nt)
  nt = parse_al.totable(nt)

  local qTable = {}
  for _, entry in ipairs(qlist) do
    if entry.MissionID == series then
      qTable[entry.QuestID] = true
    end
  end
  -- filter and assign names
  local filtered_missions = {}
  for _, mission in ipairs(missions) do
    if qTable[mission.QuestID] then
      mission._name = mission.QuestTitle and nt[mission.QuestTitle + 1] and nt[mission.QuestTitle + 1].Message or "???"
      table.insert(filtered_missions, mission)
    end
  end
  missions = filtered_missions

  -- output
  local f = io.open(process_out .. 'quests.txt', 'w')
  for i, mission in ipairs(missions) do
    local content = handle_mission(mission, series, i, mtype, missions)
    assert(f:write(content))
  end
  assert(io.close(f))
  print("quests.txt created successfully")
end

return {
  parse_mission = parse_mission
}