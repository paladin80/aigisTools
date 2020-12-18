-- parse_missions.lua
-- v1.1
-- author: lzlis

local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local handle_mission = require("missions/handle_mission")
local get_quest_list = require("missions/quest_list")

local mission_types = {
  "ChallengeMission",
  "DailyMission",
  "DevilAdventMission",
  "EmergencyMission",
  "HarlemMission",
  "RaidMission",
  "ReproduceMission",
  "StoryMission",
  "SubjugationMission",
  "AssaultMission",
  "TutorialMission",
  "TowerMission",
}

local mission_alt = {
  "DailyReproduceMission",
}

local missions = get_quest_list()

if dl.listhasfile(nil, "StoryMissionConfig.atb") then
  for _, mission in ipairs(missions) do mission._name = nil end
  for _, mtype in ipairs(mission_types) do
    local qlname = mtype .. "QuestList.atb"
    if dl.listhasfile(nil, qlname) then
      local qlist = dl.getfile(nil, qlname)
      qlist = parse_al.parse(qlist)
      qlist = parse_al.totable(qlist)
      for i, entry in ipairs(qlist) do
        local series = entry.MissionID
        local nt = "QuestNameText" .. series .. ".atb"
        if dl.listhasfile(nil, nt) then
          
          nt = dl.getfile(nil, nt)
          nt = parse_al.parse(nt)
          nt = parse_al.totable(nt)
          
          for _, mission in ipairs(missions) do
            if mission.QuestID == entry.QuestID then
              mission._name = mission.QuestTitle and nt[mission.QuestTitle + 1] and nt[mission.QuestTitle + 1].Message or "???"
              --print(entry.MissionID // 100000) os.exit()
              --print(handle_mission(mission, entry.MissionID, i, mtype, missions))
              break
            end
          end
        end
      end
    end
  end
  for _, mtype in ipairs(mission_types) do
    local qlname = mtype .. "QuestList.atb"
    if dl.listhasfile(nil, qlname) then
      local qlist = dl.getfile(nil, qlname)
      qlist = parse_al.parse(qlist)
      qlist = parse_al.totable(qlist)
      for i, entry in ipairs(qlist) do
        for _, mission in ipairs(missions) do
          if mission.QuestID == entry.QuestID then
            --print(entry.MissionID // 100000) os.exit()
            print(handle_mission(mission, entry.MissionID, i, mtype, missions))
            break
          end
        end
      end
    end
  end
  for _, malt in ipairs(mission_alt) do
    local cfgname = malt .. "Config.atb"
    if dl.listhasfile(nil, cfgname) then
      local cfg = dl.getfile(nil, cfgname)
      cfg = parse_al.parse(cfg)
      cfg = parse_al.totable(cfg)
      for i, entry in ipairs(cfg) do
        local nt = "QuestNameText" .. entry.MissionID .. ".atb"
        if dl.listhasfile(nil, nt) then
          
          nt = dl.getfile(nil, nt)
          nt = parse_al.parse(nt)
          nt = parse_al.totable(nt)
          
        else
          nt = nil
        end
        local j = 1
        for q in entry.QuestID:gmatch("%d+") do
          q = assert(tonumber(q))
          for _, mission in ipairs(missions) do
            if mission.QuestID == q then
              if nt then
                mission._name = mission.QuestTitle and nt[mission.QuestTitle + 1] and nt[mission.QuestTitle + 1].Message or "???"
              else
                mission._name = "?"
              end
              print(handle_mission(mission, entry.MissionID, j, malt, missions))
              j = j + 1
              break
            end
          end
        end
      end
    end
  end
else
  print("StoryMissionConfig.atb file was not found, please check your game data integrity")
end
