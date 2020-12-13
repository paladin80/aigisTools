local influence_lookup = require "lookup//localisation".effects_skill

local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local missile = require("lib/missile")
local ability = require("wiki/ability")

local skills = dl.getfile(nil, "SkillList.atb")
skills = parse_al.parse(skills)
skills = parse_al.totable(skills)

local skill_types = dl.getfile(nil, "SkillTypeList.atb")
skill_types = parse_al.parse(skill_types)
skill_types = parse_al.totable(skill_types)

local skill_influence = dl.getfile(nil, "SkillInfluenceConfig.atb")
skill_influence = parse_al.parse(skill_influence)
skill_influence = parse_al.totable(skill_influence)

local skill_text = dl.getfile(nil, "SkillText.atb")
skill_text = parse_al.parse(skill_text)
skill_text = parse_al.totable(skill_text)

local influence_target = {
  [1] = "RaiseMorale",
  [2] = "Self",
  [3] = "Nearby",
  [4] = "All",
  [15] = "AllEnemy",
  [17] = "NecromancerTokens",
}

-- Test: 267

-- Battle Styles
--  1 /  0 /  0 [Soldier]
--  4 /  0 /  0 [Ninja]
--  5 /  0 /  0 [Priestess Warrior]
--  6 /  0 /  0 [Mage Armor]
--  7 /  0 /  0 [Archer]
-- 11 /  0 /  0 [Healer]
-- 14 /  0 /  0 [Summoner]
-- 15 /  0 /  0 [Trap]
-- 16 /  0 /  0 [Dancer]
-- 18 / 10 /  5 [Curse User]
-- 19 /  0 /  0 [Dark Priest]
-- 21 /  0 /  0 [Hermit]

-- Collision
--  0 /  0 /  8 /  _ (Meteor Tactics, BRIONAC, Evil Energy, Ultra Meteor Tactics, Sea God Gun Toryaina, Multi-Shot, Full Auto)
--  0 /  0 / 13 / 11 (Healing Wind)
--  0 /  0 / 16 /  _ (Spike Shield, Full Guard, Enfeeble, Guardian's Holy Shield)
--  0 /  0 / 17 /  _ (Secret skill, Crosh Slash, Final Trump Card)
--  1 /  1 / 11 /  8 Swap battle style to 11 (Prayer of Solace, Heal Magic, Prayer of Solace - Fast, God Invocation, True God Invocation, Heal Magic Plus, Change Heal, 228)
--  1 /  1 / 12 /  _ (Area Heal)
--  1 /  1 / 13 / 11 (Heal Shower)
--  2 /  1 /  4 /  _ (Mode Change, Shooting Stance, Fire Breath, Super Explosive Iron Ball, Evil Sword Answerer, Whirlwind of Death, Gale Thunder, Heat Breath, jThunder Bolt, 245, Shadow Sword)
--  2 /  1 /  7 /  _ Swap battle style to 7 (Flame of Exorcism, God Invocation Cancel, True God Invocation Cancel, Change Attack, 259)
--  3 /  1 /  3 /  6 (Pegasus Wing, Little Wing, Angel Wings of Annhiliation)
--  3 /  1 /  9 /  _ (jSlow Magic, Thunder Rain, Barrier of Evil Elimination, 269)
--  3 /  1 / 10 / 12 (Barrier of Evil Sealing)
--  4 /  1 /  0 /  _ (Efreet, Phoenix, True Phoenix)
--  5 /  1 /  0 /  _ (Protection I, Protection II, Secret Arts of Bewitching, Soothing Treasure, Saint's Barrier)
--  5 /  2 /  0 /  _ (Soul Step, Passion Step, Full Support)
--  6 /  1 / 20 /  _ (Seismic Fist, Light Sword Claidheamh Soluis, Qigong Spiral Wave)

local collision_lookup = {
  [1] = "[Heal]",
  [2] = "[Attack]",
  [3] = "[AreaAttack]",
  [4] = "[SummonAttack]",
  [5] = "[AreaBuff]",
  [6] = "[GroundAttack]",
}

local collision_state_lookup = {
  [1] = "[Default]",
  [2] = "[Dancer]",
}

local function_lookup = {
  [1] = "[Melee]",
  [3] = "[Pegasus]",
  [4] = "[MeleeWithRange]",
  [5] = "[PriestWarrior]",
  [6] = "[MageArmor]",
  [7] = "[Ranged]",
  [8] = "[RangedMultiTarget]",
  [9] = "[RangedSingleAttack]",
  [11] = "[Healer]",
  [15] = "[Trap]",
  [16] = "[Passive]",
  [20] = "[GroundAttack]",
}

local function parse(id)
  local out = ""
  local skill = skills[id + 1]
  out = out .. "Skill Name: " .. skill.SkillName .. "; "
  out = out .. "ID: " .. id .. "; "
  out = out .. "Levels: " .. skill.LevelMax .. "\n"
  if id == 0 then
    return out
  end
  out = out .. "Cooldown: " .. skill.WaitTime .. " - Level\n"
  out = out .. "Duration: " .. skill.ContTime .. " .. " .. skill.ContTimeMax .. "\n"
  out = out .. "Skill Power: " .. skill.Power .. " .. " .. skill.PowerMax .. "\n"
  local text_id = skill.ID_Text
  local description = skill_text[text_id + 1]
  out = out .. "Description:\n\t" .. description.Data_Text:gsub("\n", "\n\t") .. "\n"
  if skill_text.Recode_Index ~= nil and skill_text.Recode_Index ~= 0 then
    print(skill_text.Recode_Index)
    out = out .. "Recode (?): " .. skill_text.Recode_Index .. "\n"
  end
  local type_id = skill.SkillType
  local skill_type = nil
  for _, t in ipairs(skill_types) do
    if t.SkillTypeID == type_id then
      skill_type = t
      break
    end
  end
  if skill_type ~= nil then
    local influence_id = skill_type.ID_Influence
    local influence_records = {}
    local found = false
    for _, influence in ipairs(skill_influence) do
      if influence.Data_ID == influence_id or found and influence.Data_ID == 0 then
        found = true
        table.insert(influence_records, influence)
      elseif found then
        break
      end
    end
    if #influence_records > 0 then
      local primary = influence_records[1]
      local type_fields = {}
      if primary.Type_Collision ~= 0 then
        local x = primary.Type_Collision
        x = collision_lookup[x] or x
        table.insert(type_fields, "Collision: " .. x)
      end
      if primary.Type_CollisionState ~= 0 then
        local x = primary.Type_CollisionState
        x = collision_state_lookup[x] or x
        table.insert(type_fields, "Collision State: " .. x)
      end
      if primary.Type_ChangeFunction ~= 0 then
        local x = primary.Type_ChangeFunction
        x = function_lookup[x] or x
        table.insert(type_fields, "Function: " .. x)
      end
      if primary.Data_InfluenceType == 1 and primary.Data_Target ~= 0 and primary.Data_Target ~= 2 then
        table.insert(type_fields, "X: " .. primary.Data_Target)
      end
      if #type_fields > 0 then
        out = out .. table.concat(type_fields, "; ") .. "\n"
      end
      out = out .. "Influences: (" .. influence_id .. ")\n"
    end
    for i, influence in ipairs(influence_records) do
      if i ~= 1 then
        assert(influence.Type_Collision == 0)
        assert(influence.Type_CollisionState == 0)
        assert(influence.Type_ChangeFunction == 0)
      end
      local info = influence_lookup[influence.Data_InfluenceType]
      if info then
        out = out .. "\t" .. info.name .. " (" .. influence.Data_InfluenceType .. "): "
      else
        out = out .. "\tID " .. influence.Data_InfluenceType .. ": "
      end
      if influence.Data_InfluenceType ~= 1 and influence.Data_Target ~= 0 then
        local target = influence.Data_Target
        local target_info = influence_target[target]
        if target_info then
          out = out .. "(" .. target_info .. ") "
        else
          out = out .. "(Target " .. target .. ")"
        end
      end
      local key_value = nil
      local desc = "unknown"
      local m1 = influence.Data_MulValue
      local m2 = influence.Data_MulValue2
      local m3 = influence.Data_MulValue3
      local a1 = influence.Data_AddValue
      local upperlimit = influence._HoldRatioUpperLimit
      local summary = "(" .. m1 .. "/" .. m2 .. "/" .. m3 .. "/" .. a1 .. ")"
      if info and (info.type == "flag" or info.type == "flag+value") then
        if a1 == 0 then
          desc = "FALSE"
        elseif a1 == 1 then
          desc = "TRUE"
        else
          desc = "???"
        end
        if info.type == "flag+value" then
          desc = desc .. ", " .. info.value .. " = " .. m1
        end
        desc = desc .. " " .. summary
      elseif info and info.type == "ability" and m1 == 0 and m2 == 0 and m3 == 0 then
        desc = "\n\t\t" .. ability.parse_config(a1):gsub("\n(.)", "\n\t\t%1") .. "\t\t" .. summary
      elseif info and info.type == "enum" and m1 == 0 and m2 == 0 and m3 == 0 then
        desc = (info.enum[a1] or "???") .. " " .. summary
      elseif info and info.type == "over_time" and m2 == 0 and m3 == 0 then
        desc = a1 .. " every " .. m1 .. " frames " .. summary
      elseif info and info.type == "missile" and m1 == 0 and m2 == 0 and m3 == 0 then
        desc = "\n\t\t" .. missile.parse(a1):gsub("\n(.)", "\n\t\t%1") .. "\t\t" .. summary
      elseif info and info.type == "raw" then
        desc = summary
      elseif m1 == 0 and m2 == 0 and m3 == 0 then
        desc = "= " .. a1
      else
        local pow_string
        if m2 == 100 then
          pow_string = "POW%"
        elseif m2 == 0 then
          pow_string = nil
        else
          pow_string = "(" .. (m2/100) .. "*(POW - 100) + 100)%"
        end
        if m3 ~= 0 and pow_string then
          pow_string = pow_string:gsub("POW", tostring(m3))
        end
        if upperlimit > 0 then
          pow_string = pow_string .. " (Upper limit: "..upperlimit..")"
        end
        local suffix = ""
        if a1 ~= 0 then
          suffix = ", += " .. a1
        end
        if m1 == 100 then
          if pow_string then
            desc = " *= " .. pow_string .. suffix
          else
            if suffix ~= "" then
              desc = "base" .. suffix
            else
              desc = "(no change)"
            end
          end
        else
          if pow_string then
            desc = " = " .. m1 .. "% base * " .. pow_string .. suffix
          else
            desc = " = " .. m1 .. "% base" .. suffix
          end
        end
        desc = desc .. " " .. summary
      end
      out = out .. desc .. "\n"
      if influence._Expression and influence._Expression ~= "" then
        out = out .. "\t  Expression: " .. influence._Expression .. "\n"
      end
      if influence._ExpressionActivate and influence._ExpressionActivate ~= "" then
        out = out .. "\t  Expression (Activate): " .. influence._ExpressionActivate .. "\n"
      end
    end
  end
  return out
end

local function parsewiki(id)
  local out = {}
  local skill = skills[id + 1]
  out['Name'] = skill.SkillName
  out['ID'] = id
  out['Levels'] = skill.LevelMax
  if id == 0 then
    return out
  end
  out['Cooldown'] = skill.WaitTime-skill.LevelMax
  out['Duration'] = skill.ContTime .. " .. " .. skill.ContTimeMax
  return out
end

local function find_influence(id)
  local t_lookup = {}
  for _, t in ipairs(skill_types) do
    if t.ID_Influence == id then
      t_lookup[t.SkillTypeID] = true
    end
  end
  local ids = {}
  for index, skill in ipairs(skills) do
    if t_lookup[skill.SkillType] then
      table.insert(ids, index - 1)
    end
  end
  return ids
end

local function getnextskill(id)
  local skill = skills[id + 1]
  if id == 0 then
    return out
  end
  local type_id = skill.SkillType
  local skill_type = nil
  for _, t in ipairs(skill_types) do
    if t.SkillTypeID == type_id then
      skill_type = t
      break
    end
  end
  if skill_type ~= nil then
    local influence_id = skill_type.ID_Influence
    local influence_records = {}
    local found = false
    for _, influence in ipairs(skill_influence) do
      if influence.Data_ID == influence_id or found and influence.Data_ID == 0 then
        found = true
		if influence.Data_InfluenceType == 49 then
		  return influence.Data_AddValue
		end
      elseif found then
        break
      end
	end
  end
end

local function chainparse(id)
  local skillsfound = {}
  local skill_list = {}
  local out = {}
  while not skillsfound[tostring(id)] do
	skillsfound[tostring(id)] = true
	table.insert(skill_list, id)
	if id then id = getnextskill(id) else break end
  end
  for i, skill in pairs(skill_list) do
    if skill then
	  table.insert(out, parse(skill))
	end
  end
  return table.concat(out,'\n\n')
end

local function chainparsewiki(id)
  local skillsfound = {}
  local skill_list = {}
  local out = {}
  while not skillsfound[tostring(id)] do
	skillsfound[tostring(id)] = true
	table.insert(skill_list, id)
	if id then id = getnextskill(id) else break end
  end
  for i, skill in pairs(skill_list) do
    if skill then
	  table.insert(out, parsewiki(skill))
	end
  end
  return out
end
--[[
local function chainparsewiki(id)
  local skill_list = {}
  local skill_table = {}
  while not skill_list[id] do
	table.insert(skill_list, id)
	id = getnextskill(id)
	if not id then
	  local out = {}
	  for i, skill in ipairs(skill_list) do
	    skill_table[i] = parsewiki(skill)
	  end
	  return skill_table
	end
  end
end
]]
return {
  chainparsewiki = chainparsewiki,
  chainparse = chainparse,
  parse = parse,
  parsewiki = parsewiki,
  find_influence = find_influence,
}
