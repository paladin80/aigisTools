local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local output_al = require("wiki/output_al")
local xml = require("lib/xml")
local xmldoc = require("lib/xmldoc")
local file = require("lib/file")

local class = require("lib/class")
local rarity = require("lib/rarity")
local format = require("lib/format")
local stat = require("lib/stat")
local missile = require("lib/missile")
local skill = nil -- defer
local ability = nil -- defer

--Wiki stuff (ShinyAfro) Start
local nametrans = require "lookup//localisation".name
local classtrans = require "lookup//localisation".class
local racetrans = require "lookup//localisation".race
local config = require "lookup//config"
local scale_lib = require('lib/scale_calcs')
local gm_lib = require("lib/gm")
local dumploc = config['dump directory']
--Wiki stuff (ShinyAfro) End

local class_lib = class

local names = dl.getfile(nil, "NameText.atb")
names = parse_al.parse(names)
names = parse_al.totable(names)

local status = dl.getfile(nil, "StatusText.atb")
status = parse_al.parse(status)
status = parse_al.totable(status)

local tokens = dl.getfile(nil, "TokenUnitConfig.atb")
tokens = parse_al.parse(tokens)
tokens = parse_al.totable(tokens)

local specialty = dl.getfile(nil, "UnitSpecialty.atb")
specialty = parse_al.parse(specialty)
specialty = parse_al.totable(specialty)

local cards = nil
local info = nil

local k_cc_max = 4
local k_art_max = 3

local max_preaw_level = {
  [0] = 30,
  [1] = 40,
  [2] = 50,
  [3] = 60,
  [4] = 70,
  [7] = 65,
}

local max_aw_level = {
  [3] = 80,
  [4] = 90,
  [7] = 85,
}

local affbonus = {
  [1] = "HP",
  [2] = "ATK",
  [3] = "DEF",
  [4] = "Range",
  [5] = "MR",
  [6] = "Speed",
  [7] = "Skill Duration Increase",
  [8] = "Skill CD Reduction",
  [9] = "Physical Attack Evasion",
  [13] = "Cost Reduction"
}

local art_suffix = {
  [0] = "",
  [1] = "_AW",
  [2] = "_AW2v1",
  [3] = "_AW2v2",
}

-- Wiki stuff (ShinyAfro) Start
local function getrace(unitid) --Race function
  local Cards = xmldoc.getfile(nil, 'cards')
  local Cards = xml.parse(Cards)
  local Cards = xml.totable(Cards)
 
  local SystemText = dl.getfile(nil, 'SystemText.atb')
  local SystemText = parse_al.parse(SystemText)
  
  function GetText(TypeID, FileName)
    local TypeID = Cards[unitid][TypeID]
    local text = dl.getfile(nil, FileName)
    local obj = parse_al.parse(text)
	local TextID = 0
	
	for k, v in pairs(obj) do
	  if k == 'header' or k == 'type' then else
		if v[2]['v'] == TypeID then
	      TextID = v[3]['v']
		end
	  end
    end
	
	if TextID == 0 or TextID == "0" or TextID == nil then
	  return "N/A"
	else
	  return SystemText[TextID+1][2]['v']
	end
  end
  
  local out = {}
  
  out["race"] = GetText('_TypeRace', 'PlayerRaceType.atb')
  out["assign"] = GetText("Assign", 'PlayerAssignType.atb')
  out["identity"] = GetText("Identity", 'PlayerIdentityType.atb')
  out["blood"] = GetText("Blood", 'PlayerBloodType.atb')
  
 return out
end  
-- Wiki stuff (ShinyAfro) End

local special_influence_lookup = {
  [1] = {name = "Blizzard resist", args = {"percent"}},
  [2] = {name = "(Weather 2) resist", args = {"percent"}},
  [3] = {name = "(Weather 3) resist", args = {"percent"}},
  -- 4 used on star rush / farm units
  -- 5 used on star rush / farm units
  [6] = {name = "Drop boost (gold rush platinums)", args = {"flag", "percent"}},
  --
  [9] = {name = "Unknown (spirit queen 1)", args = {"flag"}},
  --
  [11] = {name = "Unknown (spirit queen 2)", args = {"flag"}},
  [12] = {name = "Unknown (vampire)"}, -- I did double check that the real duration is indeed 12 seconds...
  -- 13 used on trap / calamity mirror / prism mirror / mist clone, etc
  [14] = {name = "Reduce enemy DEF on hit", args = {"percent", "format.%1 frames (pre-CC)", "format.%1 frames (CC)", "format.%1 frames (AW)"}},
  -- 15 used on trap
  [16] = {name = "Cannot be targeted", args = {"flag"}},
  -- 17 used on trap
  --
  -- 23 used on trap / steam tank
  --
  [25] = {name = "(Deprecated?) Maid ATK mod", args = {"format.%1% (pre-AW)", "format.%1% (AW)"}},
  [26] = {name = "(Deprecated?) Maid DEF mod", args = {"format.%1% (pre-AW)", "format.%1% (AW)"}},
  [27] = {name = "(Deprecated?) Maid cost reduction", args = {"format.%1 (pre-AW)", "format.%1 (AW)"}},
  --
  [31] = {name = "Unit combination wildcard", args = {"flag"}},
  --
  -- 33 used on star rush / farm units
  [34] = {name = "Command"},
}

local function affection(t, n, full)
  local x = t
  t = affbonus[t]
  if t == nil then
    t = "missing enum: "..x
  end
  if t == nil and t >= 1 then -- this is broke
    t = "T=" .. t
  end
  if not full then
    n = math.floor(n * .5 + .5)
  else
    n = math.floor(n * 1.2 + .5)
  end
  return t .. " +" .. n
end



local initialized = false
local function initialize()
  if not initialized then
    cards = xmldoc.getfile(nil, "cards")
    cards = xml.parse(cards)
    cards = xml.totable(cards)
    
    info = {}
    for _, card in ipairs(cards) do
      local id = card.CardID
      info[id] = {
        card = card,
        name = names[id] or ("Unit " .. id)
      }
    end
    
    for _, token_config in ipairs(tokens) do
      local id = token_config.Param_SummonUnit
      if info[id] then
        info[id].token = true
      end
    end
    
    skill = require("wiki/skill")
    ability = require("wiki/ability")
    
    initialized = true
  end
end

local icon_initialized = false
local ico = nil
local function icon_initialize()
  if not icon_initialized then
    ico = {}
    for i = 0, k_art_max do
      local file_name = string.format("ico_%02d.aar", i)
      if dl.listhasfile(nil, file_name) then
        ico[i] = dl.getfile(nil, file_name)
        ico[i] = parse_al.parse(ico[i])
      end
    end
    icon_initialized = true
  end
end

local function exists(id)
  return names[id] and names[id].Message ~= "-"
end

local function get_name(id, mode)
  local name = names[id]
  if name and name.Message ~= "-" then
    if mode then
      return name.Message
    else
      return name.Message .. " (" .. id .. ")"
    end
  else
    return "Unit " .. id
  end
end

local function has_name(id)
  local name = names[id]
  return name and name.Message ~= "-"
end

local function get_classes(id)
  
  initialize()
  
  local my_info = info[id]
  
  if not my_info.classes then
    local card = my_info.card
    local base_class = class.get(card.InitClassID)
    
    local classes = {base_class}
    local current_class = base_class
    while current_class.JobChange ~= 0 or current_class.AwakeType1 and current_class.AwakeType1 ~= 0 do
      if current_class.AwakeType1 and current_class.AwakeType1 ~= 0 then
        if card._AwakePattern == 1 or card._AwakePattern == 3 then
          local awclass = class.get(current_class.AwakeType1)
          table.insert(classes, awclass)
        end
        if card._AwakePattern == 2 or card._AwakePattern == 3 then
          local awclass = class.get(current_class.AwakeType2)
          table.insert(classes, awclass)
        end
        break
      elseif current_class.JobChange ~= 0 then
        current_class = class.get(current_class.JobChange)
        table.insert(classes, current_class)
      else
        error()
      end
    end
  
    for i = 1, #classes do
      local current_class = classes[i]
      local cc = current_class.DotNo
      if card.Rare <= 1 and cc >= 1 then
        classes[i] = nil
      end
      if card.Rare <= 2 and cc >= 2 then
        classes[i] = nil
      end
    end
    my_info.classes = classes
  end
  return my_info.classes
end

local function get_interesting_levels(id, class)
  initialize()
  
  local cc = class.DotNo
  local card = info[id].card
  local levels = {1}
  if info[id].token then
    for _, level in ipairs{50, 55, 60, 65, 70, 80, 85, 90, 99} do
      if level <= class.MaxLevel then
        table.insert(levels, level)
      end
    end
  elseif cc == 0 or cc == 1 then
    local maxlevel = math.min(class.MaxLevel, max_preaw_level[card.Rare] or class.MaxLevel)
    table.insert(levels, maxlevel)
    if card.Rare == 2 and maxlevel == 50 then
      -- include both 50 and 55 for silver
      table.insert(levels, 55)
    end
  elseif cc == 2 then
    local maxlevel = math.min(class.MaxLevel, max_aw_level[card.Rare] or class.MaxLevel)
    table.insert(levels, maxlevel)
  else
    -- no max for second awakening
    table.insert(levels, class.MaxLevel)
  end
  return levels
end

local function get_stats(id, cc, level)
  initialize()
  
  local classes = get_classes(id)
  local card = info[id].card
  
  for _, class in ipairs(classes) do
    if class.DotNo == cc and level <= class.MaxLevel then
      local rtn = {}
      rtn.hp, rtn.hpa, rtn.hpb = stat.get(level, class.MaxLevel, card.MaxHPMod, class.InitHP, class.MaxHP)
      rtn.atk, rtn.atka, rtn.atkb = stat.get(level, class.MaxLevel, card.AtkMod, class.InitAtk, class.MaxAtk)
      rtn.def, rtn.defa, rtn.defb = stat.get(level, class.MaxLevel, card.DefMod, class.InitDef, class.MaxDef)
      return rtn, class
    end
  end
  
  return nil
end

local function get_info(id, params)
  initialize()
  local inf = info[id]
  if inf then
    for _, param in ipairs(params or {}) do
      params[param] = true
    end
    local card = inf.card
    inf.battle_style = class.get_battle_style((card.InitClassID // 100) * 100)
    if params.class then
      inf.classes = get_classes(id)
    end
    if params.dot then
      if not inf.dot then
        local dot_archives = {}
        local dot = {}
        local pattern = {}
        for i = 0, k_cc_max do
          local dot_id = card["DotID" .. i]
          if dot_id == nil or dot_id == 0 then
            dot_id = card.CardID
          end
		  -- values > 20000 being a placeholder for AW2 units without new art yet
		  if dot_id >= 20000 then dot_id = dot_id - 20000 end
          if not dot_archives[dot_id] then
            local file_name = string.format("PlayerDot%04d.aar", dot_id)
            if dl.listhasfile(nil, file_name) then
              local dot_arch = dl.getfile(nil, file_name)
              dot_arch = parse_al.parse(dot_arch)
              dot_archives[dot_id] = dot_arch
            end
          end
          dot[i] = dot_archives[dot_id]
          pattern[i] = (0x35000 + i * 10000 + dot_id) << 4
        end
        inf.dot = dot
        inf.pattern = pattern
      end
    end
  end
  return inf
end

local function parse(id)
  get_info(id, {"dot"})
  if info[id] == nil then
    return "Unit " .. id .. " is not found"
  end
  local unit_name = nametrans(id) or string.format("%03d", id)
  local card = info[id].card
  local name = get_name(id)
  local translatedname = nametrans(id) or 'Non-Translated.'
  local out = ""
  if nametrans(id) then
  out = out .. "ENName: " .. translatedname .. "\n"
  out = out .. "JPName: " .. name .. "\n"
  else
  out = out .. "Name: " .. name .. "\n"
  end
  
  -- categorization
  local Affiliations = getrace(id)
  out = out .. "Rarity: " .. rarity.get_name(card.Rare) .. "\n"
  out = out .. "Gender: " .. format.gender(card.Kind) .. "\n"
  if racetrans(Affiliations["race"]) then
    out = out .. "Race: " .. racetrans(Affiliations["race"])..' ('..Affiliations["race"] .. ")\n"
  else
    out = out .. "Race: " .. Affiliations["race"] .. "\n"
  end
  if racetrans(Affiliations["assign"]) then
    out = out .. "Affiliation: " .. racetrans(Affiliations["assign"])..' ('..Affiliations["assign"] .. ")\n"
  else
    out = out .. "Affiliation: " .. Affiliations["assign"] .. "\n"
  end
  if racetrans(Affiliations["identity"]) then
    out = out .. "Special: " .. racetrans(Affiliations["identity"])..' ('..Affiliations["identity"] .. ")\n"
  else
    out = out .. "Special: " .. Affiliations["identity"] .. "\n"
  end
  if racetrans(Affiliations["blood"]) then
    out = out .. "Bloodline: " .. racetrans(Affiliations["blood"])..' ('..Affiliations["blood"] .. ")\n\n"
  else
    out = out .. "Bloodline: " .. Affiliations["blood"] .. "\n\n"
  end
  
  -- overall parameters
  out = out .. "Magic resistance (base): " .. card.MagicResistance .. "\n"
  
  local battle_style = info[id].battle_style
  local battle_style_range = {}
  if battle_style then
    out = out .. "Class battle style: " .. battle_style.Type_BattleStyle .. "\n"
    if battle_style._Param_01 ~= 0 then
      out = out .. "Class parameter 1: " .. battle_style._Param_01 .. "\n"
    end
    if battle_style._Param_02 ~= 0 then
      out = out .. "Class parameter 2: " .. battle_style._Param_02 .. "\n"
    end
    for i = 0, k_cc_max do
      battle_style_range[i] = battle_style[string.format("_Range_%02d", i + 1)]
    end
  end
  
  out = out .. "\n"
  out = out .. "Gold value (discharge): " .. card.SellPrice .. "; Rainbow crystal value (discharge): " .. card._TradePoint .. "\n"
  out = out .. "EXP value (combine): " .. card.BuildExp .. "\n\n"
  
  local function handle_class(class, cc, has_next)
    local ranged = class.ApproachFlag == 0
    
    out = out .. "Class: " .. class.Name .. " (" .. cc .. ")\n"
    out = out .. "Description:\n\t" .. format.indent(class.Explanation) .. "\n"
    out = out .. "Ranged: " .. (ranged and "yes" or "no") .. "\n"
    if not ranged then
      out = out .. "Block count: " .. class.BlockNum .. "\n"
      if battle_style_range[cc] and battle_style_range[cc] ~= 0 then
        out = out .. "Range: " .. battle_style_range[cc] .. "\n"
      end
    else
      out = out .. "Range: " .. class.AtkArea .. "\n"
    end
    out = out .. "Target/attack count: " .. class.MaxTarget .. "\n"
    out = out .. "Attack attribute: " .. format.get_enum("attack_attribute", class.AttackAttribute) .. "\n"
    out = out .. "EXP value per level (combination): " .. class.BuildExp .. "\n"
    out = out .. "\n"
    
    if class.ClassAbility1 ~= 0 then
      out = out .. "Class ability:\n\t"
      out = out .. format.indent(ability.parse_config(class.ClassAbility1))
    end
    
    out = out .. "\n"
    
    if ranged then
      out = out .. missile.parse(class.MissileID) .. "\n"
    end
    
    local levels = get_interesting_levels(id, class)
    
    out = out .. "Stats (HP, ATK, DEF):\n"
    for _, level in ipairs(levels) do
      local hp, hpa = stat.get(level, class.MaxLevel, card.MaxHPMod, class.InitHP, class.MaxHP)
      local atk, atka = stat.get(level, class.MaxLevel, card.AtkMod, class.InitAtk, class.MaxAtk)
      local def, defa = stat.get(level, class.MaxLevel, card.DefMod, class.InitDef, class.MaxDef)
      out = out .. string.format("Lv%02d  %7s %6s %6s\n", level, hp .. hpa, atk .. atka, def .. defa)
    end
    out = out .. "\n"
    out = out .. "Max cost: " .. (class.Cost + card.CostModValue) .. "; Min cost: " .. (class.Cost + card.CostModValue - card.CostDecValue) .. "\n"
    
    local aff_bonuses = {}
    local full_affection_bonus = class.MaxLevel > 50 -- maybe not the true condition...
    if card.BonusType ~= 0 then
      table.insert(aff_bonuses, affection(card.BonusType, card.BonusNum, full_affection_bonus))
    end
    if card.BonusType2 ~= 0 then
      table.insert(aff_bonuses, affection(card.BonusType2, card.BonusNum2, full_affection_bonus))
    end
    if card.BonusType3 ~= 0 then
      table.insert(aff_bonuses, affection(card.BonusType3, card.BonusNum3))
    end
    if #aff_bonuses > 0 then
      out = out .. "Affection bonus(es): " .. table.concat(aff_bonuses, "; ") .. "\n"
    end
    out = out .. "\n"
    
    -- animation info
    local animations = {}
    local unit_pattern = info[id].pattern[cc]
    if info[id].dot[cc] then
    for _, archfile in ipairs(info[id].dot[cc]) do
      if archfile.name:match("%.aod$") then
        local aod = archfile.value
        local pattern = aod.mt and aod.mt.pattern
        if pattern then
          pattern = pattern & ~0xf
          if pattern == unit_pattern then
            animations[archfile.name] = aod
          end
        end
      end
    end
    end
    
    for _, anim_name in ipairs{"Attack.aod", "Atk2.aod"} do
      local anim = animations[anim_name]
      if anim then
        local n = anim_name:match("%P+")
        local anim_len = anim.mt.length
        local attack_frame = class.AttackAnimNo
        out = out .. n .. ":" .. (" "):rep(7 - #n) .. format.pad("(" .. anim_len, 4) .. "+1) + " .. format.pad("(" .. class.AttackWait, 4) .. "+1) = " .. format.pad(anim_len + class.AttackWait + 2, 3) .. "\n"
       
        if anim.mt.entries[1].data.PatternNo[1 + attack_frame] then
          local attack_time = anim.mt.entries[1].data.PatternNo[1 + attack_frame].time -- +1 is Lua-indexing offset
          out = out .. "Initial: (" .. attack_time .. "+1)           = " .. format.pad(attack_time + 1, 3) .. "\n"
        else
          out = out .. "Initial: (bad) frame " .. attack_frame .. "\n"
        end
        
        out = out .. "Timing:  " .. (anim.mt.entries[1].data.PatternNo[1].time or "???")
        for i = 2, #anim.mt.entries[1].data.PatternNo do
          out = out .. " / " .. anim.mt.entries[1].data.PatternNo[i].time
        end
        out = out .. "\n\n"
      end
    end
    
    -- tokens
    for _, token_config in ipairs(tokens) do
      if token_config.ID_Class == class.ClassID then
        if token_config.Param_CardID == 0 or token_config.Param_CardID == card.CardID then
          out = out .. "Token: " .. get_name(token_config.Param_SummonUnit) .. "\n"
          out = out .. "Token cost: " .. token_config.Param_SummonCost .. "\n"
          out = out .. "Token count: " .. token_config.Param_SummonLimit .. "\n"
          out = out .. "Token deploy limit: " .. token_config.Param_SummonMax .. "\n"
          out = out .. "Token deploy cooldown: " .. token_config.Param_SummonRecast .. "\n\n"
        end
      end
    end
    
    -- class change/awakening materials
    if has_next and class.JobChange ~= 0 then
      out = out .. "Class change materials:\n"
      for i = 1, 3 do
        local material = class["JobChangeMaterial" .. i]
        if material ~= 0 then
          local mat_class = class_lib.get(material)
          out = out .. "\t" .. mat_class.Name .. "\n"
        end
      end
      for i = 1, 2 do
        local orb = class["Data_ExtraAwakeOrb" .. i]
        if orb ~= 0 then
          local orb_class = class_lib.get(orb)
          out = out .. "\t" .. orb_class.Name .. " Orb\n"
        end
      end
      out = out .. "\n"
    end
    
  end
  
  local classes = get_classes(id)
  
  for i, current_class in ipairs(classes) do
    local has_next = classes[i + 1] ~= nil
    local cc = current_class.DotNo
    handle_class(current_class, cc, has_next)
  end
  
  if card.ClassLV0SkillID ~= 0 then
    out = out .. "Base skill:\n\n"
    out = out .. (skill.chainparse(card.ClassLV0SkillID) or (skill.chainparse(card.ClassLV1SkillID)) or 'N/A') .. "\n"
  end
  
  if card.ClassLV1SkillID ~= 0 and card.ClassLV1SkillID ~= card.ClassLV0SkillID then
    out = out .. "Class-evolved skill:\n\n"
    out = out .. skill.chainparse(card.ClassLV1SkillID) .. "\n"
  end
  
  if card.EvoSkillID ~= 0 and card.EvoSkillID ~= card.ClassLV1SkillID then
    out = out .. "Awakened skill:\n\n"
    out = out .. skill.chainparse(card.EvoSkillID) .. "\n"
  end
  
  if card.Ability_Default ~= 0 then
    out = out .. "Non-awakened ability:\n\n"
    out = out .. ability.parse(card.Ability_Default) .. "\n"
  end
  
  if card.Ability ~= 0 then
    if card._AppearAbilityLevel ~= 0 then
      out = out .. "Level " .. card._AppearAbilityLevel .. " ability:\n\n"
    else
      out = out .. "Awakened ability:\n\n"
    end
    out = out .. ability.parse(card.Ability) .. "\n"
  end
  
  local special_influences = {}
  local found = false
  for _, special in ipairs(specialty) do
    if special.ID_Card == 0 and found or special.ID_Card == card.CardID then
      found = true
      table.insert(special_influences, special)
    elseif found then
      break
    end
  end
  
  if #special_influences > 0 then
    out = out .. "Special properties:\n"
    for _, influence in ipairs(special_influences) do
      local params = {
        influence.Value_Specialty,
        influence.Value_Param1, influence.Value_Param2,
        influence.Value_Param3, influence.Value_Param4,
      }
      out = out .. "\t" .. format.indent(format.format(special_influence_lookup, influence.Type_Specialty, params))
      if influence.Command and influence.Command ~= "" then
        out = out .. "\t  Command: " .. influence.Command .. "\n"
        local notes = format.get_notes(influence.Command)
        if notes ~= "" then
          out = out .. "\t  " .. format.indent(notes, "\t  ")
        end
      end
    end
    out = out .. "\n"
  end
  
  --getting Julian and Crave to tell us whether adjutant's implemented or not.
  local adjutant = (info[8].card.Flavor - info[7].card.Flavor) == 8
  
  if card.LoveEv1 ~= 0 then
    out = out .. "Quotes:\n"
    local loves = {0, math.floor(card.LoveEv1 / 2), card.LoveEv1, 50, 60, 80, 100}
    for i, love in ipairs(loves) do
      out = out .. format.pad(love, 3) .. "%: " .. tostring(status[card.Flavor + i].Message):gsub("%s+", " ") .. "\n"
    end
    if adjutant then
      out = out .. "Adjutant quote: " .. tostring(status[card.Flavor + 8].Message):gsub("%s+", " ") .. "\n"
    end
  if card.Flavor2 ~= 0 then
      out = out .. "130%: " .. tostring(status[card.Flavor2].Message):gsub("%s+", " ") .. "\n"  
      out = out .. "150%: " .. tostring(status[card.Flavor2 + 1].Message):gsub("%s+", " ") .. "\n"  
    end
  else
    out = out .. "Quote: " .. tostring(status[card.Flavor + 1].Message):gsub("%s+", " ") .. "\n"
  end
  
  if card.Illust ~= 0 then
    out = out .. "\nArtist: " .. tostring(status[card.Illust + 1].Message) .. "\n"
  end
  
  return out
end

local function get_name_noid(id)
  local name = names[id]
  if name and name.Message ~= "-" then
    return name.Message
  else
    return "Unit " .. id
  end
end

local function format_stats(cc, stat, value, ikey, ivalue)
  if cc then
    cc = cc+1
    if value and type(value) == 'number' then
      return string.format('|c%d%-'..ikey..'s = %-'..ivalue..'d', cc, stat, value)
    elseif value and type(value) == 'string' then
      return string.format('|c%d%-'..ikey..'s = %-'..ivalue..'s', cc, stat, value)
    elseif not value then
	  --key = key + 3
      return string.format('|c%d%-'..ikey..'s', cc, stat)
    end
  else
    --key = key + 2
    if value and type(value) == 'number' then
      return string.format('|%-'..ikey..'s = %-'..ivalue..'d', stat, value)
    elseif value and type(value) == 'string' then
      return string.format('|%-'..ikey..'s = %-'..ivalue..'s', stat, value)
    elseif not value then
	  --local key = key + 3
      return string.format('|%-'..ikey..'s', stat)
    end
  end
end

local function parsewiki(id)
  local abilitynametable = {}
  local skillnametable = {}
  get_info(id, {"dot"})
  if info[id] == nil then
    return "Unit " .. id .. " is not found"
  end
  local f_stats = '%-5d'
  local statsdump = ""
  local card = info[id].card
  local unit_name = nametrans(id) or string.format("%03d", id)
  local name = nametrans(id) or get_name(id)
  local jpname = get_name(id):gsub(' %(%d+%)', '')
  local classes = get_classes(id)
  local class = (classtrans(classes[1]['Name'])) or (classes[1]['Name'])
  if card.Illust ~= 0 then
    artist = tostring(status[card.Illust + 1].Message)
  else 
    artist = "Undisclosed"
  end
  local statsout = ""
  
  local battle_style = info[id].battle_style
  local battle_style_range = {}
  if battle_style then
    for i = 0, k_cc_max do
      battle_style_range[i] = battle_style[string.format("_Range_%02d", i + 1)]
    end
  end
  
  local function handle_class(class, cc, has_next)
    local statsdump = ''
    local ranged = class.ApproachFlag == 0
    statsdump = statsdump .. "|c" .. (cc+1) .. "Class = " .. (classtrans(class.Name) or class.Name) .. "\n"
	
    if format.indent(ability.parse_config(class.ClassAbility1)):match('MR mod[^%+]*%+(%d+)') then
	  magic_resist_class = format.indent(ability.parse_config(class.ClassAbility1)):match('MR mod[^%+]*%+(%d+)')
	else
	  magic_resist_class = 0
	end
    local levels = get_interesting_levels(id, class)
    
    for _, level in ipairs(levels) do
      local hp, hpa = stat.get(level, class.MaxLevel, card.MaxHPMod, class.InitHP, class.MaxHP)
      local atk, atka = stat.get(level, class.MaxLevel, card.AtkMod, class.InitAtk, class.MaxAtk)
      local def, defa = stat.get(level, class.MaxLevel, card.DefMod, class.InitDef, class.MaxDef)
	  if n and n == 1 then
		n = nil
		local maxlevel = ""
		if cc < 3 then maxlevel = format_stats(cc,'MaxLvl',level,7,0) end
		statsdump = statsdump..format_stats(cc,'MaxHP',hp,7,6)..format_stats(cc,'MaxAtk',atk,7,6)..format_stats(cc,'MaxDef',def,7,6)..maxlevel..'\n'
	  else
		n = 1
		local mr = tonumber(tostring((card.MagicResistance+magic_resist_class)):match('([^%.]+)'))
		statsdump = statsdump..format_stats(cc,'MinHP',hp,7,6)..format_stats(cc,'MinAtk',atk,7,6)..format_stats(cc,'MinDef',def,7,6)..format_stats(cc,'Resist',mr,7,0)..'\n'
	  end
    end
    if not ranged then
      statsdump = statsdump..format_stats(cc,'Block',class.BlockNum,7,6)
      if battle_style_range[cc] and battle_style_range[cc] ~= 0 then
        statsdump = statsdump..format_stats(cc,'Range',battle_style_range[cc],7,6)
	  else
        statsdump = statsdump..format_stats(cc,'Range','',7,6)
      end
    else
      local range = tonumber(tostring(class.AtkArea):match('([^%.]+)'))
      statsdump = statsdump..format_stats(cc,'Block','',7,6)
      statsdump = statsdump..format_stats(cc,'Range',class.AtkArea,7,6)
	end
	local mincost = format_stats(cc,'MinCost',(class.Cost + card.CostModValue - card.CostDecValue),7,0)
	local maxcost = format_stats(cc,'MaxCost',(class.Cost + card.CostModValue),7,6)
	if card.CostDecValue == 0 then maxcost = format_stats(cc,'MaxCost',"-",7,6) end
    statsdump = statsdump..maxcost..mincost..'\n'
    
    local aff_bonuses = {}
    local full_affection_bonus = class.MaxLevel > 50 -- maybe not the true condition...
    if card.BonusType ~= 0 then
      table.insert(aff_bonuses, affection(card.BonusType, card.BonusNum, full_affection_bonus))
    end
    if card.BonusType2 ~= 0 then
      table.insert(aff_bonuses, affection(card.BonusType2, card.BonusNum2, full_affection_bonus))
    end
    if card.BonusType3 ~= 0 then
      table.insert(aff_bonuses, affection(card.BonusType3, card.BonusNum3, full_affection_bonus))
    end
    if #aff_bonuses > 0 then
	  if classevol and cc == 0 then
	    str = string.gsub(table.concat(aff_bonuses, "<br>"),'%s','')
	    str = string.gsub(str,'Speed[+](%d+)','ATK Delay -%1%%')
        statsdump = statsdump .. "|50AffBonus = " .. str .. "\n"
	  elseif classevol and cc == 1 then
	    str = string.gsub(table.concat(aff_bonuses, "<br>"),'%s','')
	    str = string.gsub(str,'Speed[+](%d+)','ATK Delay -%1%%')
        statsdump = statsdump .. "|100AffBonus = " .. str .. "\n"
	  elseif cc == 0 then
	    str = string.gsub(table.concat(aff_bonuses, "<br>"),'%s','')
	    str = string.gsub(str,'Speed[+](%d+)','ATK Delay -%1%%')
        statsdump = statsdump .. "|100AffBonus = " .. str .. "\n"
	  end
    end
	statsdump = statsdump .. (skillnametable[cc+1] or '')
	statsdump = statsdump .. (abilitynametable[cc+1] or '')
    statsdump = statsdump .. "\n"
	return statsdump
  end
  
  --Unit Infobox
  local pageout = '{{Unit infobox'..'\n'
  pageout = pageout .. "|name = " .. name ..' <!--'..id..'-->' .. "\n"
  pageout = pageout .. "|gender = " .. format.gender(card.Kind) .. "\n"
  pageout = pageout .. "|rank = " .. rarity.get_name(card.Rare) .. "\n"
  pageout = pageout .. "|class = " .. class .. "\n"
  pageout = pageout .. "|jpname = " .. jpname .. '\n'
  pageout = pageout .. "|artist = " .. artist .. "\n"
  pageout = pageout .. "}}\n\n"
  
  --Intro
  pageout = pageout .. "'''"..name.."'''"..' is a [[:Category:Rarity:'..rarity.get_name(card.Rare)..'|'..string.lower(rarity.get_name(card.Rare))..']] [[:Category:'..class..'s|'..string.lower(class)..']].' .. '\n\n'
  pageout = pageout .. 'Obtained from:' .. '\n'
  pageout = pageout .. '* <!-- Obtain method goes here -->' .. '\n'
  pageout = pageout .. '__TOC__' .. '\n'
  pageout = pageout .. '<br clear="all"/>' .. '\n'
  
  --Stats
  pageout = pageout .. '== Stats ==' .. '\n'
  pageout = pageout .. '{{Unitlist start|ability=yes}}' .. '\n'
  pageout = pageout .. '{{:'..name..'/stats}}' .. '\n'
  pageout = pageout .. '{{Unitlist end}}' .. '\n\n'
  
  
  if card.ClassLV0SkillID ~= 0 then
    local skilltable = skill.parsewiki(card.ClassLV0SkillID)
	pageout = pageout .. '== Skill ==' .. '\n'
	pageout = pageout .. '{{:Skill/'..skilltable['Name']..'|'..rarity.get_name(card.Rare)..'}}' .. '\n'
	skillnametable[1] = '|c1Skill = '..skilltable['Name'].. '\n'
  end
  
  if card.ClassLV1SkillID ~= 0 and card.ClassLV1SkillID ~= card.ClassLV0SkillID then
    local skilltable = skill.parsewiki(card.ClassLV1SkillID)
	pageout = pageout .. '{{:Skill/'..skilltable['Name']..'|'..rarity.get_name(card.Rare)..'}}' .. '\n'
	skillnametable[2] = '|c2Skill = '..skilltable['Name'].. '\n'
  else
  for k, v in pairs(get_classes(id)) do
	if get_classes(id)[k]['DotNo'] and get_classes(id)[k]['DotNo'] == 1 then
	  skillnametable[2] = skillnametable[1]:gsub('|c1Skill = ','|c2Skill = ').. '\n'
    end
  end
    
  end
  
  pageout = pageout .. '\n'
  
  if card.EvoSkillID ~= 0 and card.EvoSkillID ~= card.ClassLV1SkillID then
	pageout = pageout .. '== Skill Awakening ==' .. '\n'
    pageout = pageout .. '{{Skill awakening list begin}}' .. '\n'
    pageout = pageout .. '{{Skill awakening item' .. '\n'
    pageout = pageout .. '|name = '..name.. '\n'
	if card.ClassLV1SkillID ~= 0 and card.ClassLV1SkillID ~= card.ClassLV0SkillID then
		local skilltable = skill.parsewiki(card.ClassLV1SkillID)
		pageout = pageout .. '|skill = ' ..skilltable['Name'] .. '\n'
		pageout = pageout .. '|effect = ' .. '\n'
		pageout = pageout .. '|reuse = ' ..skilltable['Cooldown'] .. '\n\n'
	else
		local skilltable = skill.parsewiki(card.ClassLV0SkillID)
		pageout = pageout .. '|skill = ' ..skilltable['Name'] .. '\n'
		pageout = pageout .. '|effect = ' .. '\n'
		pageout = pageout .. '|reuse = ' ..skilltable['Cooldown'] .. '\n\n'
	end
    local skilltable = skill.chainparsewiki(card.EvoSkillID)
	for i, skill in ipairs(skilltable) do
	  if i == 1 then i = "" end
	  pageout = pageout .. '|awSkill'..i..' = ' ..skill['Name'] .. '\n'
	  pageout = pageout .. '|awEffect'..i..' = ' .. '\n'
	  pageout = pageout .. '|awReuse'..i..' = ' ..(skill['Cooldown'] or "??") .. '\n'
	  if i == "" then i = 1 end
	if next(skilltable,i) then pageout = pageout .. '\n' end
	end
	pageout = pageout .. '}}' .. '\n'
	local skilltable = skill.parsewiki(card.EvoSkillID)
	pageout = pageout .. '{{Skill awakening list end}}' .. '\n\n'
    skillnametable[3] = '|c3Skill = '..skilltable['Name'].. '\n'
  end
  
  --Ability 
  
  if card.Ability_Default ~= 0 then
	abilitytable = ability.parsewiki(card.Ability_Default)
	pageout = pageout .. '== Ability ==' .. '\n'
	pageout = pageout .. '{{Abilitylist start}}' .. '\n'
	pageout = pageout .. '{{:Ability/'..abilitytable['Name']..'}}' .. '\n'
	abilitynametable[1] = '|c1Ability = '..abilitytable['Name'].. '\n'
	if card.Ability ~= 0 then
	  abilitytable = ability.parsewiki(card.Ability)
      pageout = pageout .. '{{:Ability/'..abilitytable['Name']..'}}' .. '\n'
      abilitynametable[3] = '|c3Ability = '..abilitytable['Name'].. '\n'
    end
	pageout = pageout .. '{{Abilitylist end}}' .. '\n' .. '\n'
  else
	abilitytable = ability.parsewiki(card.Ability)
	pageout = pageout .. '== Ability ==' .. '\n'
	pageout = pageout .. '{{Abilitylist start}}' .. '\n'
    pageout = pageout .. '{{:Ability/'..abilitytable['Name']..'}}' .. '\n'
    abilitynametable[3] = '|c3Ability = '..abilitytable['Name'].. '\n'
	pageout = pageout .. '{{Abilitylist end}}' .. '\n' .. '\n'
  end
  
  --Class Attributes  
  pageout = pageout .. '== Class Attributes ==' .. '\n'
  pageout = pageout .. '{{:Class/'..class..'}}' .. '\n\n'
  
  --Quotes 
  if card.LoveEv1 ~= 0 then
    pageout = pageout .. "== Affection ==".. "\n"
    pageout = pageout .. "=== Quotes - highlight the pink lines to see them. ===".. "\n"
    pageout = pageout .. "{{Quote table".. "\n"
    local loves = {0, math.floor(card.LoveEv1 / 2), card.LoveEv1, 50, 60, 80, 100}
	n = 0
    for i, love in ipairs(loves) do
	  n = n + 1
      pageout = pageout ..'|%'..n..' = '..format.pad(love, 3) .. "% |quote"..n.." = <!--" .. tostring(status[card.Flavor + i].Message):gsub("%s+", " ") .. "-->\n"
    end
    pageout = pageout .. "|quote8 = <!--" .. tostring(status[card.Flavor + 8].Message):gsub("%s+", " ") .. "-->\n"
  if card.Flavor2 ~= 0 then
      pageout = pageout .. "|quote9 = <!--" .. tostring(status[card.Flavor2].Message):gsub("%s+", " ") .. "-->\n"
      pageout = pageout .. "|quote10 = <!--" .. tostring(status[card.Flavor2 + 1].Message):gsub("%s+", " ") .. "-->\n}}\n"
    end
  else
    pageout = pageout .. "Quote: " .. tostring(status[card.Flavor + 1].Message):gsub("%s+", " ") .. "\n"
  end
  pageout = pageout .. "\n"
  
  --Scenes
  pageout = pageout .. '=== Scenes ===' .. "\n"
  pageout = pageout .. '{{Scenes' .. "\n"
  pageout = pageout .. '|%1 = 30%  |Scene 1 =' .. "\n"
  pageout = pageout .. '|%2 = 100% |Scene 2 =' .. "\n"
  pageout = pageout .. '}}' .. "\n\n"
  
  --CC/AW Mats
  for k, v in pairs(get_classes(id)) do
	if get_classes(id)[k]['DotNo'] and get_classes(id)[k]['DotNo'] == 1 then
	  pageout = pageout ..'== Class Change Materials =='..'\n'
	  pageout = pageout ..'{{:Class Change/'..class..'s|'..rarity.get_name(card.Rare)..'}}'..'\n\n'
	  ccclass = get_classes(id)[k]['Name']
	elseif get_classes(id)[k]['DotNo'] and get_classes(id)[k]['DotNo'] == 2 then
	  if ccclass and classtrans(ccclass) then
		ccclass = classtrans(ccclass)
	  elseif ccclass == nil then
		ccclass = class
	  end
	  pageout = pageout ..'== Awakening Materials =='..'\n'
	  pageout = pageout ..'{{:Awakening/'..ccclass..'s|'..rarity.get_name(card.Rare)..'}}'..'\n\n'
    end
  end
  
  --Gallery
  pageout = pageout .. '== Gallery ==' .. "\n"
  pageout = pageout .. '{{gallery|auto=' .. "\n"
  pageout = pageout .. '}}'
  
  -- Header
  statsout = statsout .. '{{Unitlist start|ability=yes}}'..'\n'
  statsout = statsout .. '<onlyinclude>{{{{{format|Unitlist item}}}'..'\n'
  statsout = statsout .. '|1 = {{{1|}}}'..'\n\n'
  
  -- categorization  and stats
  for i, current_class in ipairs(get_classes(id)) do
    local has_next = classes[i + 1] ~= nil
    local cc = current_class.DotNo
	if get_classes(id)[i]['DotNo'] and get_classes(id)[i]['DotNo'] == 1 then
		statsout = statsout .. '|classevol = y' .. '     '
		classevol = true
	elseif get_classes(id)[i]['DotNo'] and get_classes(id)[i]['DotNo'] == 2 then
		statsout = statsout .. '|awaken = y' .. '        '
	elseif get_classes(id)[i]['DotNo'] and get_classes(id)[i]['DotNo'] == 3 then
		statsout = statsout .. '|awaken2A = y' .. '      '
	elseif get_classes(id)[i]['DotNo'] and get_classes(id)[i]['DotNo'] == 4 then
		statsout = statsout .. '|awaken2B = y'
	end
  end
  
  for i, current_class in ipairs(get_classes(id)) do
    local has_next = classes[i + 1] ~= nil
    local cc = current_class.DotNo
    statsdump = statsdump..handle_class(current_class, cc, has_next)
  end
  local Affiliations = getrace(id)
  local sname = (nametrans(id) or name)
  local srare = rarity.get_name(card.Rare)
  local srace = (racetrans(Affiliations["race"]) or Affiliations["race"])
  local sassi = (racetrans(Affiliations["assign"]) or Affiliations["assign"])
  local sspec = (racetrans(Affiliations["identity"]) or Affiliations["identity"])
  local sgender = string.lower(format.gender(card.Kind))
  statsout = statsout .. '\n'
  statsout = statsout .. format_stats(nil,"name", sname, 4,11)
  statsout = statsout .. format_stats(nil,"gender", sgender, 6,9)
  statsout = statsout .. format_stats(nil,"rarity", srare, 6,0)
  statsout = statsout .. '\n'
  statsout = statsout .. format_stats(nil,"race", srace, 4,11)
  if sassi ~= "N/A" and sspec == "N/A" then statsout = statsout .. format_stats(nil,"affiliation", sassi, 6,0) end
  if sassi ~= "N/A" and sspec ~= "N/A" then statsout = statsout .. format_stats(nil,"affiliation", sassi, 6,9) end
  if sspec ~= "N/A" then statsout = statsout .. format_stats(nil,"affiliation", sspec, 6,0) end
  statsout = statsout .. '\n\n'
  statsout = statsout .. statsdump
  
  --End of page
  statsout = statsout .. '}}</onlyinclude>'
  statsout = statsout .. '{{Unitlist end}}'
  return {pageout, statsout}
end

local function wikidump(id, out, working)
  if config and config['Named directories'] == true and nametrans(id) then
  out = (config['Named unit directory'] or out) .. nametrans(id) .. '/wiki/'
  else
  out = out .. string.format("%03d", id) .. '/wiki/'
  end
  local unit_name = nametrans(id) or string.format("%03d", id)
  local name = get_name(id)
  local is_english = true
  for i = 1, #name do
    if string.byte(name, i) >= 128 then
      is_english = false
      break
    end
  end
  if is_english then
    out = out .. "_" .. name:gsub(" ", "_")
  end
  if not file.dir_exists(out) then
    file.make_dir(out)
  end
  out = out .. "/"
  local text = parsewiki(id)
  local hpage = assert(io.open(out .. "page.txt", 'w'))
  local hstat = assert(io.open(out .. "stats.txt", 'w'))
  --local hinfo = assert(io.open(out .. "stats.txt", 'w'))
  assert(hpage:write(text[1]))
  assert(hstat:write(text[2]))
  --assert(hinfo:write(text[3]))
  if config['File Printouts'] then print('page.txt generated') end
  if config['File Printouts'] then print('stats.txt generated') end
  --print('Info.txt generated')
  assert(hpage:close())
  assert(hstat:close())
  --assert(hinfo:close())
end

local function imagedump(id, out, working, mode)
  if mode['dump'] and not file.dir_exists(config['dump directory']) then file.make_dir(config['dump directory']) end
  initialize()
  local unit_name = nametrans(id) or string.format("%03d", id)
  if config and config['Named directories'] == true and nametrans(id) then
  out = (config['Named unit directory'] or out) .. nametrans(id)
  else
  out = out .. string.format("%03d", id)
  end
  
  if rarity.get_name(info[id].card.Rare) ~= 'Black' then
	art_suffix_B = {[0] = "", [1] = "_CC", [2] = "_AW", [3] = "_AW2", [4] = "_AW2",}
	art_suffix_C = {[0] = "", [1] = "_AW", [2] = "_AW2",[3] = "_AW2"}
  else
	art_suffix_B = { [0] = "", [1] = "_CC", [2] = "_AW",   [3] = "_AW2v1", [4] = "_AW2v2",}
	art_suffix_C = { [0] = "", [1] = "_AW", [2] = "_AW2v1",[3] = "_AW2v2",}
  end
  image_set_cc = {[0] = 'base',[1] = 'cc',[2] = 'aw', [3] = 'aw2',[4] = 'aw2',}
  image_set = {   [0] = 'base',[1] = 'aw',[2] = 'aw2',[3] = 'aw2'}
  if not config['PNGout render Printouts'] then png_suffix_render = ' >nul 2>&1' else png_suffix_render = '' end
  if not config['PNGout sprite Printouts'] then png_suffix_sprite = ' >nul 2>&1' else png_suffix_sprite = '' end
  if not config['PNGout icon Printouts'] then png_suffix_icon = ' >nul 2>&1' else png_suffix_icon = '' end
  
  wikiout = out .. '/wiki/'
  local name = get_name(id)
  local is_english = true
  
  for i = 1, #name do
    if string.byte(name, i) >= 128 then
      is_english = false
      break
    end
  end
  if is_english then
    out = out .. "_" .. name:gsub(" ", "_")
  end
  if not file.dir_exists(wikiout) then
    file.make_dir(wikiout)
  end
  if not file.dir_exists(out..'\\images') then
    file.make_dir(out..'\\images')
  end
  if not file.dir_exists(out) then
    file.make_dir(out)
  end
  
  out = out .. "\\"
  out = out:gsub(' ','_')
  local function output_png(id, i, filename)
    listname = string.format("%03d_card_%d.png", id, i)
    if dl.listhasfile(nil, listname) then
      local image = dl.getfile(nil, listname)
      local h = assert(io.open(out .. filename .. ".png", 'wb'))
      assert(h:write(image))
      assert(h:close())
    elseif dl.listhasfile(nil, string.format("Card%04d.aar", id) ) then
      return true
    end
  end
  
  local function suffixer(cc,animate)
    local temp = art_suffix_B[tonumber(cc:match('dot(%d*)'))]:gsub('_','')
    cc, animate = tonumber(cc:sub(-1)) + 1, tonumber(animate)
    if cc > 2 and animate > 5 then
      temp = 'S' .. temp
    elseif animate > 5 then
	  if cc ~= 1 then
	    temp = temp .. '_'
	  end
      temp = temp .. 'Skill'
    end
    if temp ~= '' then
      temp = '_' .. temp
    end
    if animate % 5 == 3 then
      temp = temp .. "_Attack"
    end
    return temp
  end
  
  if mode["full"] or mode["image"] or mode["sprite"] or mode["gif"] then
    if config['iSet Startup Printouts'] then print('Starting '..unit_name..' sprites') end
    get_info(id, {"dot"})
    if info[id] and info[id].dot then
      for cc = 0, k_cc_max do
	    if mode[image_set_cc[cc]] then
          if info[id].dot[cc] then
            for _, f in ipairs(info[id].dot[cc]) do
              local aod = f.value
              local pattern = aod.mt and aod.mt.pattern
              if pattern then
                local aod_id = pattern & 0xf
                pattern = pattern & ~0xf
                --print(pattern, unit_pattern)
                if pattern == info[id].pattern[cc] then
  		          output_al.output(f.value, out .. string.format("dot%d\\%02d_%s\\", cc, aod_id, f.name), working, {textures = info[id].dot[cc].textures})
                end
              end
            end
          end
		end
      end
    end
	if not mode['gif'] and not mode["image"] and not mode['full'] then
      if not file.dir_exists(out .. '\\images\\') then file.make_dir(out .. '\\images\\') end
      local cmd = assert(io.popen('cmd /c dir '..out..' /b', "r"))
      local h = cmd:read('*a')
      cmd:close()
      for dot in h:gmatch('dot%d') do
	    if mode[image_set_cc[tonumber(dot:match('%d+'))]] then
	      scale_lib.do_scale(out..'\\'..dot..'\\01_Stand.aod\\alod_SP00_00.png', cards[id].DotScale)
		  scale_lib.do_scale(out..'\\'..dot..'\\05_Damage.aod\\alod_SP00_00.png', cards[id].DotScale)
		  local outputdir
		  if mode['dump'] then outputdir = config['dump directory'] else outputdir = out..'\\images\\' end
	  	  os.execute('cmd /c pngout  '..out..'\\'..dot..'\\01_Stand.aod\\alod_SP00_00_scaled.png' .. png_suffix_sprite)
	      os.execute('cmd /c move  '..out..'\\'..dot..'\\01_Stand.aod\\alod_SP00_00_scaled.png '..
	  	    outputdir..unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))].."_Sprite.png >nul 2>&1")
		  os.execute('cmd /c pngout  '..out..'\\'..dot..'\\05_Damage.aod\\alod_SP00_00_scaled.png' .. png_suffix_sprite)
	      os.execute('cmd /c move  '..out..'\\'..dot..'\\05_Damage.aod\\alod_SP00_00_scaled.png '..
	  	    outputdir..unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))].."_Death_Sprite.png >nul 2>&1")
		  if config['Image Cleanup'] then
            os.execute('cmd /c rmdir  '..out..'\\'..dot..' /s /q  >nul 2>&1')
		  end
		  if config['File Printouts'] then print(unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))]..'_Sprite.png generated') end
		end
      end
	end
	if config['iSet Completion Printouts'] then print(unit_name..' sprites completed') end
  end
  
  if mode["full"] or mode["image"] or mode['icon'] then
    if config['iSet Startup Printouts'] then print('Starting '..unit_name..' icons') end
    icon_initialize()
    for i = 0, k_art_max do
      if ico[i] then
	    if mode[image_set[i]] then
          for _, f in ipairs(ico[i]) do
            if f.name:match("%.atx$") then
              local get_frame = {
                index = id,
                name = unit_name..art_suffix_C[i].."_Icon",
              }
              output_al.output(f.value, out, working, {get_frame = get_frame})
            end
          end
		  if config['pngout'] then os.execute('cmd /C pngout '..out..unit_name..art_suffix_C[i].."_Icon.png" .. png_suffix_icon) end
		  local outputdir
		  if mode['dump'] then outputdir = config['dump directory'] else outputdir = out..'\\images\\' end
		  os.execute('cmd /C move '..out..unit_name..art_suffix_C[i].."_Icon.png "..outputdir..' >nul 2>&1')
		  if config['File Printouts'] then print(unit_name..art_suffix_C[i]:gsub('_',' ').." Icon.png generated.") end
        end
	  end
    end
	if config['iSet Completion Printouts'] then print(unit_name..' icons completed') end
  end
  
  if mode["full"] or mode["image"] or mode["gif"] then
    if config['iSet Startup Printouts'] then print('Starting '..unit_name..' gifs') end   
    local cmd = assert(io.popen('cmd /c dir '..out..' /b', "r"))
    local h = cmd:read('*a')
    cmd:close()
    for dot in h:gmatch('dot%d') do
      if mode[image_set_cc[tonumber(dot:match('%d+'))]] then
          local cmd = io.popen('cmd /C dir '..out..'\\'..dot..' /B', "r")
          animlist = cmd:read('*a')
            --print(animlist)
          cmd:close()
          for anim in animlist:gmatch('%d+_[%a%d_]+.aod') do
            local cmd = io.popen('cmd /C dir '..out..'\\'..dot..'\\'..anim..' /B', "r")
            imagelist = cmd:read('*a')
            cmd:close()
            local action_folder = out..'\\'..dot..'\\'..anim.."\\"
            if (anim:match('Stand') or anim:match('Damage')) and (mode["full"] or mode["image"] or mode["sprite"]) then
			  local anim_suffix = ""
			  if anim:match('Damage') then anim_suffix = "_Death" end
              local sprite = imagelist:match('(alod_SP%d+_%d*.png)')
              os.execute('cmd /c copy '..action_folder..sprite..' '..out..'\\images\\'..unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))]..anim_suffix.."_Sprite.png >nul 2>&1")
              scale_lib.do_scale(out..'\\images\\'..unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))]..anim_suffix.."_Sprite.png", cards[id].DotScale)
              os.execute('cmd /c del '..out..'\\images\\'..unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))]..anim_suffix.."_Sprite.png >nul 2>&1")
              os.execute('cmd /c rename '..out..'\\images\\'..unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))]..anim_suffix.."_Sprite_scaled.png "
                                                  ..unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))]..anim_suffix.."_Sprite.png >nul 2>&1")
              if config['pngout'] then  os.execute('cmd /c pngout '..out..'\\images\\'..unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))].."_Sprite.png" .. png_suffix_sprite) end
			  if config['File Printouts'] then print(unit_name..art_suffix_B[tonumber(dot:match('dot(%d*)'))]..anim_suffix..'_Sprite.png generated') end
            end
            --Re-purposed illumini9's mass-resize and gif-make right about here.
            if file.file_exists(action_folder .. "ALMT.txt") then
              local dimensions = {left = 0, top = 0, right = 0, bottom = 0}
              -- collating origins to adjust to appropriate size
              for pic in imagelist:gmatch('(alod_SP%d+_%d+.png)') do
                local pfile = io.popen('gm identify ' .. action_folder .. pic)
                local widxhei = pfile:read('*a')
                assert(pfile:close())
                local wid, hei = widxhei:match("PNG (%d+)x(%d+)%+0%+0")
                wid = tonumber(wid); hei = tonumber(hei)
                local teh_file = assert(io.open(action_folder .. pic:sub(1,-4) .. "txt", 'rb'))
                local file_content = teh_file:read('*a')
                assert(teh_file:close())
                local originx, originy = file_content:match("origin_x:(%d+).+origin_y:(%d+)")
				--Cutoff for massive X/Y transforms which can cause massive slowdowns. 
				if (config['GIF XY Cutoff'] and tonumber(originx)>config['GIF XY Cutoff']) or (config['GIF XY Cutoff'] and tonumber(originy)>config['GIF XY Cutoff']) then break end
                originx = tonumber(originx); originy = tonumber(originy)
                local right = wid - originx
                local bottom = hei - originy
                if dimensions["left"] < originx then dimensions["left"] = originx end
                if dimensions["top"] < originy then dimensions["top"] = originy end
                if dimensions["right"] < (wid - originx) then dimensions["right"] = (wid - originx) end
                if dimensions["bottom"] < (hei - originy) then dimensions["bottom"] = (hei - originy) end
              end
              local nudge_directory = action_folder .. 'nudged\\'
              if not file.dir_exists(nudge_directory) then file.make_dir(nudge_directory) end
              local scale_directory = action_folder .. 'scaled'
              --if unit_scale then scale_directory = scale_directory .. '_' .. unit_scale end
              scale_directory = scale_directory .. '\\'
              if not file.dir_exists(scale_directory) then file.make_dir(scale_directory) end
              os.execute('gm convert -size ' .. dimensions["left"] + dimensions["right"] ..
                'x' .. dimensions["top"] + dimensions["bottom"] .. ' xc:none working\\background.miff')
              for pic in imagelist:gmatch('alod_SP%d+_%d+.png') do
                local file_path = action_folder .. pic
                local result_path = nudge_directory .. pic
                if force == "force" or not file.file_exists(scale_directory .. pic:sub(1,-5) .. '_scaled.png') then
                  local teh_file = assert(io.open(file_path:sub(1,-4) .. "txt", 'rb'))
                  local file_content = teh_file:read('*a')
                  assert(teh_file:close())
                  local originx, originy = string.match(file_content,"origin_x:(%d+).+origin_y:(%d+)")
				  --Cutoff for massive X/Y transforms which can cause massive slowdowns. 
				  if (config['GIF XY Cutoff'] and tonumber(originx)>config['GIF XY Cutoff']) or (config['GIF XY Cutoff'] and tonumber(originy)>config['GIF XY Cutoff']) then break end
                  local geometry = '-geometry +' .. dimensions["left"] - tonumber(originx) .. '+' .. dimensions["top"] - tonumber(originy) .. ' '
                  assert(file.file_exists('working\\background.miff'))
                  os.execute('gm composite ' .. geometry .. file_path .. ' working\\background.miff ' .. result_path)
                  if config['pngout'] then os.execute('pngout' .. ' ' .. result_path .. png_suffix_sprite) end
                  unit_scale = cards[id].DotScale
                  scale_lib.do_scale(result_path, unit_scale, scale_directory)
                end
                if config['pngout'] then os.execute('pngout' .. ' ' .. scale_directory .. pic:sub(1,-5) .. '_scaled.png' .. png_suffix_sprite) end
              end
            end
          end
        end
      end
	
    local cmd = assert(io.popen('cmd /c dir '..out..' /b', "r"))
    local h = cmd:read('*a')
    cmd:close()
    for dot in h:gmatch('dot%d') do
	  if mode[image_set_cc[tonumber(dot:match('%d+'))]] then
        local cmd = io.popen('cmd /C dir '..out..'\\'..dot..' /B', "r")
        animlist = cmd:read('*a')
        cmd:close()
        for anim in animlist:gmatch('%d+_[%a%d_]+.aod') do
          local action_folder = out..'\\'..dot..'\\'..anim.."\\"
          if file.file_exists(action_folder .. 'ALMT.txt') then
            if not file.dir_exists(out .. '\\images\\') then file.make_dir(out .. '\\images\\') end
            h = assert(io.open(action_folder .. 'ALMT.txt', 'rb'))
            local text = assert(h:read('*a'))
            assert(h:close())
            local steps = {}
            for sec_mark in text:gmatch("%d @(...)%:") do
              table.insert(steps, sec_mark)
            end
            if steps[1] ~= "N/A" then
              for step, sec_mark in ipairs(steps) do
                local next_mark = steps[step+1]
                if next_mark then
                  steps[step] = tonumber(next_mark) - tonumber(sec_mark)
                else
                  steps[step] = 1
                end
              end
              local edited_folder = 'scaled'
              local gifname = unit_name..suffixer(dot,anim:sub(1,2))..'_Sprite.gif'
              local ext = '_scaled.png '
              local cmd = io.popen('cmd /C dir '..action_folder..edited_folder .. '\\ /B', "r")
              steplist = cmd:read('*a')
              cmd:close()
              local _, count = string.gsub(steplist, ".png", "")
		      --if #steps == count then print(anim) end
			  --print(count)
              if file.dir_exists(action_folder .. edited_folder .. '\\') and #steps == count then
                if force == 'force' or not file.file_exists(action_folder .. gifname) then
                  local args = 'magick -dispose previous -loop 0 '
                  for step, secs in ipairs(steps) do
                    if next(steps,step) ~= nil then
                      args = args .. '-delay ' .. secs .. 'x60' .. ' ' .. action_folder .. edited_folder .. '\\'
                      args = args .. 'alod_SP00_' .. string.format("%02d", step - 1) .. ext
                    end
                  end
		          local outputdir
		          if mode['dump'] then outputdir = config['dump directory'] else outputdir = out..'\\images\\' end
                  args = args .. outputdir .. gifname .. '  >nul 2>&1'
                  os.execute(args)
				  --print(args)
				  if config['File Printouts'] then print(unit_name..suffixer(dot,anim:sub(1,2)):gsub('_',' ')..' Sprite.gif generated') end
                end
              end
            end
          end
        end
      end
	end
    --The last of mass-resize / gif-make (repurposed)
    local cmd = assert(io.popen('cmd /c dir '..out..' /b', "r"))
    local h = cmd:read('*a')
    cmd:close()
	if config['Image Cleanup'] then
      for dot in h:gmatch('dot%d') do
          os.execute('cmd /c rmdir  '..out..'\\'..dot..' /s /q  >nul 2>&1')
      end
      os.execute('cmd /c rmdir  '..out..'\\gifs /s /q  >nul 2>&1')
	end
	if config['iSet Completion Printouts'] then print(unit_name..' gifs complete') end
  end
  
  if mode["full"] or mode["image"] or mode["render"] then
    if config['iSet Startup Printouts'] then print('Starting '..unit_name..' renders') end
    for i = 0, k_art_max do
	    if mode[image_set[i]] then
        local AllAgesImages = output_png(id, i,unit_name..art_suffix_C[i].."_Render" )
        if (AllAgesImages) and (i == 0) then
          local image = dl.getfile(nil, string.format("Card%04d.aar", id) )
          image = parse_al.parse(image)
          for k, v in pairs(image) do --name sample : 323_card_0.atx (use for suffix?)
            if (type(v)=="table") and (v.name) and (v.name:match("%.atx$")) then
              local i = v.name:match("%d+_card_(%d).atx")
              --for k, v in pairs(v.value) do
                print (v.value.type)
              --end
              local get_frame = {
                index = 0,
                name = unit_name..art_suffix_C[tonumber(i)].."_Render",
              }
              output_al.output(v.value, out, working, {get_frame = get_frame})
              print(v.value, out, working, {get_frame = get_frame}, get_frame.index, get_frame.name)
            end
          end
          --image = image[1]["value"]["rawimage"]["image"]
          --local h = assert(io.open(out .. "Test" .. ".png", 'wb'))
          --assert(h:write(image))
          --assert(h:close())
        end
  	    if config['render pngout'] and config['pngout'] then os.execute('cmd /C pngout '..out..unit_name..art_suffix_C[i].."_Render.png" .. png_suffix_render) end
		    local outputdir
		    if mode['dump'] then outputdir = config['dump directory'] else outputdir = out..'\\images\\' end
  	    os.execute('cmd /C move '..out..unit_name..art_suffix_C[i].."_Render.png "..outputdir..'>nul 2>&1')
		    if config['File Printouts'] then print(unit_name..art_suffix_C[i]:gsub('_',' ').."_Render.png generated") end
	    end
    end
	  if config['iSet Completion Printouts'] then print(unit_name..' renders completed.') end
  end

  if (file.file_exists(out..'wiki\\page.txt')) then
    h = assert(io.open(out .. "wiki\\page.txt", 'r'))
	text = h:read('*a')
    assert(h:close())
	local cmd = assert(io.popen('cmd /c dir '..out..'images\\ /b', "r"))
    local h = cmd:read('*a')
	--print(h)
	text = text:gsub('({{gallery|auto=)[^%}]*(}})', '%1\n'..h..'%2')
    cmd:close()
    h = assert(io.open(out .. "wiki\\page.txt", 'w'))
    assert(h:write(text))
    if config['File Printouts'] then print('page.txt gallery updated.') end
    assert(h:close())
  end
end

local function textdump(id, out, working)
  if config and config['Named directories'] == true and nametrans(id) then
    out = (config['Named unit directory'] or out) .. nametrans(id)
  else
    out = out .. string.format("%03d", id)
  end
  local name = get_name(id)
  local is_english = true
  for i = 1, #name do
    if string.byte(name, i) >= 128 then
      is_english = false
      break
    end
  end
  if is_english then
    out = out .. "_" .. name:gsub(" ", "_")
  end
  if not file.dir_exists(out) then
    file.make_dir(out)
  end
  out = out .. "/"
  local text = parse(id)
  local h = assert(io.open(out .. "info.txt", 'w'))
  assert(h:write(text))
  if config['File Printouts'] then print('info.txt generated') end
  assert(h:close())
  
  text = text..'\n\ntext output at '..out..'info.txt'
  
  if config and config['Get Unit Text Console Dump'] ~= true then
	text = 'text output at '..out..'info.txt'
  end

  
  return text
end

local function just_quotes(id, mode)
  get_info(id, {"dot"})
  if info[id] == nil then
    return "Unit " .. id .. " is not found"
  end
  local card = info[id].card
  if card.LoveEv1 ~= 0 then
    out = "Quotes:\n"
    local loves = {0, math.floor(card.LoveEv1 / 2), card.LoveEv1, 50, 60, 80, 100}
    for i, love in ipairs(loves) do
      out = out .. format.pad(love, 3) .. "%: " .. tostring(status[card.Flavor + i].Message):gsub("%s+", " ") .. "\n"
    end
    out = out .. "Adjutant quote: " .. tostring(status[card.Flavor + 8].Message):gsub("%s+", " ") .. "\n"
  else
    out = out .. "Quote: " .. tostring(status[card.Flavor + 1].Message):gsub("%s+", " ") .. "\n"
  end
  if mode and mode['dump'] then
    local h = assert(io.open(dumploc .. "\\" .. (nametrans(id) or id) .. "_Quotes.txt", 'w'))
    assert(h:write(out))
    assert(h:close())
  end
  return out
end

return {
  exists 	= exists,
  get_name 	= get_name,
  has_name 	= has_name,
  get_info	= get_info,
  parse 	= parse,
  dump 		= dump,
  textdump 	= textdump,
  pagedump 	= wikidump,
  imagedump = imagedump,
  just_quotes = just_quotes,
  just_skills = just_skills,
}
