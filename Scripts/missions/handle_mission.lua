local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local format = require("lib/format")
local unit = require("lib/unit")
local config = require "lookup//config"

local init_terms = require("missions/terms")
local lib_enemies = require("missions/enemies")
local get_treasure_names = require("missions.treasure")

local maps = {}
local entries = {}
local messagetexts = {}
local enemiesmap = {}
local battletalks = {}
local available_maps = {}

local enemies
local term_text
local messages
local unitnames
local treasure_decode
local enemygfx_names
local guest_lookup

local function init()
  if config['iSet Startup Printouts'] then print('Loading mission datafiles') end
  local text = dl.getfile(nil, "MessageText.atb")
  messages = parse_al.parse(text)

  text = dl.getfile(nil, "NameText.atb")
  unitnames = parse_al.parse(text)

  term_text = init_terms()
  enemies = lib_enemies.init_enemies()
  enemygfx_names = lib_enemies.get_enemy_gfx_names()
  treasure_decode = get_treasure_names()

  text = dl.getfile(nil, "QuestGuestUnitConfig.atb")
  local guests = parse_al.parse(text)
  guests = parse_al.totable(guests)
  guest_lookup = {}
  for _, guest in ipairs(guests) do
    local qid = guest.ID_Quest
    local guests = guest_lookup[qid] or {}
    guest_lookup[qid] = guests
    table.insert(guests, guest)
  end

  local files = dl.getlist_raw()

  for mapn in files:gmatch("Map(%d+)%.aar") do
    mapn = tonumber(mapn, 10)
    assert(mapn)
    assert(not available_maps[mapn])
    available_maps[mapn] = true
  end
end

local function handle_mission(mission, series, series_i, mtype, missions)
  if config['iSet Startup Printouts'] then print('Generating description for ' .. mission) end

  local buffer = ""
  local function print2(...)
    local arg = {...}
    local s = table.concat(arg, " ")
    buffer = buffer .. s .. '\n'
  end

  if not enemies then init() end

  local mapn = tonumber(mission.MapNo)
  if available_maps[mapn] and not maps[mapn] then
    local mapname = string.format("Map%03d.aar", mapn)
    local text = dl.getfile(nil, mapname)
    local map = parse_al.parse(text)
    maps[mapn] = map
    entries[mapn] = {}
    for _, archfile in ipairs(map) do
      local entryn = archfile.name:match("Entry(%d+)%.atb")
      if entryn then
        entries[mapn][tonumber(entryn, 10)] = assert(archfile.value)
      end
    end
  end
  
  if series and not messagetexts[series] then
    local mt = "MessageText" .. series .. ".atb"
    if dl.listhasfile(nil, mt) then
      mt = dl.getfile(nil, mt)
      mt = parse_al.parse(mt)
      mt = parse_al.totable(mt)
      messagetexts[series] = mt
    end
  end
  local mt = series and messagetexts[series]
  
  if series and not enemiesmap[series] then
    local ene = "Enemy" .. series .. ".atb"
    if dl.listhasfile(nil, ene) then
      ene = dl.getfile(nil, ene)
      ene = parse_al.parse(ene)
      ene = parse_al.totable(ene)
      enemiesmap[series] = ene
    end
  end
  local ene = series and enemiesmap[series] or enemies
  
  if series and not battletalks[series] then
    local bt = "BattleTalkEvent" .. series .. ".atb"
    if dl.listhasfile(nil, bt) then
      bt = dl.getfile(nil, bt)
      bt = parse_al.parse(bt)
      bt = parse_al.totable(bt)
      battletalks[series] = bt
    end
  end
  local bt = series and battletalks[series]
  
  local map = maps[mapn]
  if map then
    local entryn = tonumber(mission.EntryNo)
    local entry = entries[mapn][entryn]
    if entry then
      local field_indices = {}
      for idx, field in ipairs(entry.header.object) do
        field_indices[field.name_en] = idx
      end
      local kEnemyID = assert(field_indices.EnemyID)
      local kLoop = assert(field_indices.Loop)
      local kLevel = assert(field_indices.Level)
      local kPrizeCardID = assert(field_indices.PrizeCardID)
      local kPrizeEnemyDropPercent = assert(field_indices.PrizeEnemyDropPercent)
      local kEntryCommand = assert(field_indices.EntryCommand)
      
      local mob_counts = {}
      local mob_min_levels = {}
      local mob_max_levels = {}
      local missing_mobs = {}
      local treasure_counts = {}
      local mob_level_counts = {}
      local enemy_total = 0
      local bonus_treasure = {}
      local dialog = {}
      
      for _, mob in ipairs(entry) do
        local wt, wlct = nil, nil
        if mtype == "SubjugationMission" then
          local wave = enemy_total // 100 + 1
          wt = mob_counts[wave] or {}
          --io.stderr:write("wave:",wave,"\n")
          mob_counts[wave] = wt
          
          wlct = mob_level_counts[wave] or {}
          mob_level_counts[wave] = wlct
        end
        local mob_counts = wt or mob_counts
        local mob_level_counts = wlct or mob_level_counts
        
        local id = mob[kEnemyID].v
        local skip_total = false
        if id >= 6000 and id <= 7999 then
          if id >= 7000 then
            skip_total = true -- optional replacement enemy
          end
          id = id % 1000
        end
        --if enemies[id] then
        if id >= 1 and id <= 999 then
          local count = mob_counts[id] or 0
          --assert(mob[kLoop].v > 0)
          count = count + mob[kLoop].v
          if not skip_total then
            enemy_total = enemy_total + mob[kLoop].v
          end
          mob_counts[id] = count
          local level_counts = mob_level_counts[id] or {}
          mob_level_counts[id] = level_counts
          level_counts[mob[kLevel].v] = (level_counts[mob[kLevel].v] or 0) + mob[kLoop].v
          if mob_min_levels[id] then
            mob_min_levels[id] = math.min(mob_min_levels[id], mob[kLevel].v)
            mob_max_levels[id] = math.max(mob_max_levels[id], mob[kLevel].v)
          else
            mob_min_levels[id] = mob[kLevel].v
            mob_max_levels[id] = mob[kLevel].v
          end
        elseif id >= 1 and id <= 999 then
          io.stderr:write("unavailable enemy: " .. id .. "\n")
          missing_mobs[id] = true
        end
        if id >= 1 and id <= 999 then
          local treasure = mob[kPrizeCardID].v
          local bonus = mob[kPrizeEnemyDropPercent].v
          if bonus > 0 then
            table.insert(bonus_treasure, bonus)
          elseif treasure > 0 then
            local tcount = treasure_counts[treasure] or 0
            tcount = tcount + mob[kLoop].v
            treasure_counts[treasure] = tcount
          end
        end
        if id == 4201 then
          -- EntryCommand
          local command = mob[kEntryCommand].v
          if bt and command:match("^CallEvent%([%d, ]+%)%;$") then
            local offset = bt[1].RecordOffset
            local seq = {}
            for event in command:gmatch("%d+") do
              event = assert(tonumber(event)) - offset + 1
              local t = assert(bt[event])
              table.insert(seq, t.Name .. ": " .. t.Message:gsub("\n", " "):gsub(" +", " "))
            end
            if #seq > 0 then
              table.insert(dialog, seq)
            end
          end
        end
      end
      print2((series and (series .. "/" ) or "")..mission.QuestID, mission._name, "Level = " .. mission.Level)
      print2("map=" .. mission.MapNo, "entry=" .. mission.EntryNo, "location=" .. mission.LocationNo)
      if mission.AppearCondition ~= 0 then
        if missions then
          for _, p in ipairs(missions) do
            if p.QuestID == mission.AppearCondition then
              print2("prerequisite=" .. p._name)
            end
          end
        else
          print2("prerequisite=" .. mission.AppearCondition)
        end
      end
      print2("enemies=".. enemy_total, "cha="..mission.Charisma, "sta="..mission.ActionPoint)
      print2("exp="..mission.RankExp, "gold="..mission.Gold)
      print2("life="..mission.defHP, "startUP="..mission.defAP, "unitLimit="..mission.Capacity)
      if mission.QuestTerms ~= 0 then
        print2("terms="..mission.QuestTerms)
        if term_text[mission.QuestTerms] then
          print2(term_text[mission.QuestTerms])
        end
      end
      if mission._HardLevel ~= 0 or mission._HardCondition ~= 0 or mission._HardInfomation ~= 0 then
        print2("hard="..mission._HardCondition, "HL="..mission._HardLevel)
        if mission._HardCondition ~= 0 and term_text[mission._HardCondition] then
          print2(term_text[mission._HardCondition])
        end
        if mission._HardInfomation ~= 0 then
          local hi
          --[[
          if mt then
            hi = mt[mission._HardInfomation + 1].Message
          elseif messages and messages[mission._HardInfomation + 1] then
            hi = messages[mission._HardInfomation + 1][1].v
          else
            hi = "???"
          end
          print2("hinfo="..string.format("%q", hi):gsub("\\\n", "\n"))
          ]]
        end
      end
      local quote
      if mt then
        if mt[mission.Text + 1] then
          quote = mt[mission.Text + 1].Message
        else
          quote = "???"
        end
      elseif messages and messages[mission.Text + 1] then
        quote = messages[mission.Text + 1][1].v
      else
        quote = "???"
      end
      print2("quote="..string.format("%q", quote):gsub("\\\n", "\n"))
      for i = 1, 5 do
        local treasure_key = string.format("Treasure%d", i)
        local treasure = mission[treasure_key]
        local count = treasure_counts[i] or 0
        if treasure > 0 then
          local reward_name = tostring(treasure)
          if treasure >= 1 and treasure <= 999 and unitnames[treasure] then
            reward_name = unitnames[treasure][1].v .. " (" .. treasure .. ")"
          end
          if treasure_decode[treasure] then
            reward_name = treasure_decode[treasure]
          end
          print2("Reward " .. i, reward_name, "x" .. count, "lv" .. mission.UnitLevel)
        end
      end
      for _, treasure in ipairs(bonus_treasure) do
        local reward_name = tostring(treasure)
        if treasure >= 1 and treasure <= 999 and unitnames[treasure] then
          reward_name = unitnames[treasure][1].v .. " (" .. treasure .. ")"
        end
        if treasure_decode[treasure] then
          reward_name = treasure_decode[treasure]
        end
        print2("Reward X", reward_name)
      end
      local it_a, it_b, it_c = ipairs{mob_counts}
      if mtype == "SubjugationMission" then
        it_a, it_b, it_c = ipairs(mob_counts)
      end
      for wave, mob_counts in it_a, it_b, it_c do
        local wt = nil
        if mtype == "SubjugationMission" then
          print2("Wave " .. wave)
          wt = mob_level_counts[wave]
        end
        local mob_level_counts = wt or mob_level_counts
        for id, count in pairs(mob_counts) do
          --print2(" ", id, enemies[id]._name, "x" .. count, "Level = " .. mob_min_levels[id] .. " .. " .. mob_max_levels[id])
          for lvl, count in pairs(mob_level_counts[id]) do
            --io.stderr:write(id .. "\n")
            local ene_name = ene[id] and ene[id]._name
            if ene[id] and ene_name == nil then
              local pattern = (ene[id].PatternID - 0x00200000) // 0x100
              ene_name = enemygfx_names[pattern]
              --print2(id, pattern, ene_name)
            end
            if ene_name == nil or ene_name == "" then
              ene_name = "?"
            end
            print2(" ", id, ene_name, "x" .. count, "Level = " .. lvl)
          end
        end
      end
      for id, _ in pairs(missing_mobs) do
        print2(" ", "missing", id)
      end
      print2()
      if guest_lookup[mission.QuestID] then
        for _, guest in ipairs(guest_lookup[mission.QuestID]) do
          print2("Guest: " .. unit.get_name(guest.ID_Card))
          print2("Location: " .. guest.ID_PlaceID)
          print2("Level: " .. guest.Param_Level)
          print2("Affection: " .. guest.Param_Love)
          print2("Skill level: " .. guest.Param_SkillLevel)
          print2("Class change: " .. format.get_enum("cc", guest.Param_ClassChange))
          if guest.Param_ExpressionCommand ~= 0 then
            print2("Expression: " .. guest.Param_ExpressionCommand)
          end
          print2()
        end
      end
      if #dialog > 0 then
        for _, seq in ipairs(dialog) do
          for _, t in ipairs(seq) do
            print2(t)
          end
          print2()
        end
      end
    else
      io.stderr:write("unavailable entry: " .. mapn .. "/" .. entryn .. " for mission " .. mission.QuestID .. " " .. mission._name .. "\n")
    end
  else
    io.stderr:write("unavailable map: " .. mapn .. "\n")
    --print2(mission, series)
  end
  return buffer
end

return handle_mission