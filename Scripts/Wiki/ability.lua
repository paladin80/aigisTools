local influence_lookup = require "lookup//localisation".effects_ability

local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local class = require("lib/class")
local missile = require("lib/missile")
local unit = require("wiki/unit")
local rarity = require("lib/rarity")

local abilities = dl.getfile(nil, "AbilityList.atb")
abilities = parse_al.parse(abilities)
abilities = parse_al.totable(abilities)

local configs = dl.getfile(nil, "AbilityConfig.atb")
configs = parse_al.parse(configs)
configs = parse_al.totable(configs)

local ability_text = dl.getfile(nil, "AbilityText.atb")
ability_text = parse_al.parse(ability_text)
ability_text = parse_al.totable(ability_text)

local k_skill_chance_boost = "opt.format.+%1% chance during skill"
local k_max_percent = "format.max %1%"
local k_threshold_percent = "format.%1% threshold"
local k_frames = "format.%1 frames"
local k_nekomata = {"format.enemy %1%", "format.ally %1%"}

local enums = {
  priority = {
    [1] = "MAGIC",
    [2] = "RANGED",
  },
  state = {
    [1] = "IDLE",
    [2] = "DURING_SKILL",
    [3] = "NOT_DURING_SKILL",
  },
  weather = {
    [1] = "BLIZZARD",
  },
  gender = {
    [0] = "MALE",
    [1] = "FEMALE",
  },
  enemy_type = {
    [1] = "ARMOR",
    [2] = "DRAGON",
    [3] = "DEMON",
    [4] = "YOKAI",
    [5] = "GOLEM",
    [6] = "ANGEL",
    [7] = "MERMAN",
    [8] = "ORC",
    [9] = "GOBLIN",
  },
}

-- Invoke
-- 1: [Default] Instant Death Strike, Flaming War Spear, Rapid Fire, Priority Magic
-- 2: [Sortie] All Attack Up (S), Unit Points Up
-- 3: [Placement] Minor Heal
-- 4: [Deployed] Pursuit, Miracle Shield, Increased Evasion, Certain Kill Attack

-- Target
-- 1: [Self] Pursuit, Miracle Shield, Increased Evasion, Instant Death Strike, Certain Kill Attack, Flaming War Spear, Rapid Fire
-- 2: [All] Minor Heal, All Attack Up (S), Unit Points Up

local invoke_lookup = {
  [0] = "[Default]",
  [1] = "[Inherent]",
  [2] = "[Sortie]",
  [3] = "[Placement]",
  [4] = "[Deployed]",
}

local target_lookup = {
  [0] = "[Default]",
  [1] = "[Self]",
  [2] = "[All]",
}

local parse_config

local function parse(id)
  local out = ""
  local ability = abilities[id + 1]
  assert(ability.AbilityID == id)
  out = out .. "Ability Name: " .. ability.AbilityName .. "\n"
  out = out .. "(Deprecated?) Ability Power: " .. ability.AbilityPower .. "; Ability Type: " .. ability.AbilityType .. "\n"
  local text_id = ability.AbilityTextID
  local description = ability_text[text_id + 1]
  out = out .. "Description:\n\t" .. description.AbilityText:gsub("\n", "\n\t") .. "\n"
  local config_id = ability._ConfigID
  if config_id == 0 then
    out = out .. "Influences: (none)\n"
  else
    out = out .. parse_config(config_id)
  end
  return out
end

local function parsewiki(id)
  local out = {}
  local ability = abilities[id + 1]
  assert(ability.AbilityID == id)
  out['Name'] = ability.AbilityName
  out['Power'] = ability.AbilityPower
  out['Type'] = ability.AbilityType
  local text_id = ability.AbilityTextID
  local description = ability_text[text_id + 1]
  out['Description'] = description.AbilityText:gsub("\n", "\n\t")
  local config_id = ability._ConfigID
  if config_id == 0 then
    out['Influences'] = "Influences: (none)"
  else
    out['Influences'] = parse_config(config_id)
  end
  return out
end

function parse_config(id)
  local out = ""
  local influence_records = {}
  local found = false
  for _, influence in ipairs(configs) do
    if influence._ConfigID == id or found and influence._ConfigID == 0 then
      found = true
      table.insert(influence_records, influence)
    elseif found then
      break
    end
  end
  out = out .. "Config ID: " .. id .. "\n"
  if #influence_records > 0 then
    out = out .. "Influences:\n"
    for _, influence in ipairs(influence_records) do
      local params = table.concat({influence._Param1, influence._Param2, influence._Param3, influence._Param4}, "/")
      local itype = influence._InfluenceType
      local info = influence_lookup[itype]
      local post = {}
      if info then
        out = out .. "\t" .. info.name .. " (" .. itype .. "):"
        if info.args then
          out = out .. " "
          local first = true
          local stop = false
          for i, arg in ipairs(info.args) do
            local opt = false
            if arg:match("^opt%.") then
              opt = true
              arg = assert(arg:match("^opt%.(.*)$"))
            end
            local str = ""
            local param = influence["_Param" .. i]
            if arg == "_" or opt and param == 0 then
              -- nothing
            elseif arg == "n" then
              str = param
            elseif arg == "range" then
              str = param .. " range"
            elseif arg == "add_n" then
              if param < 0 then
                str = param
              else
                str = "+" .. param
              end
            elseif arg == "mod" then
              str = "x" .. (param/100)
            elseif arg == "chance" then
              str = param .. "% chance"
            elseif arg == "percent" then
              str = param .. "%"
            elseif arg == "add_percent" then
              if param < 0 then
                str = param .. "%"
              else
                str = "+" .. param .. "%"
              end
            elseif arg == "delay" then
              str = param .. " frame delay"
            elseif arg == "class" then
              if param == 0 then
                -- nothing
              else
                str = class.get_name_p(param)
              end
            elseif arg == "missile" then
              --str = "missile " .. param
              local mis_str = missile.parse(param)
              table.insert(post, mis_str)
            elseif arg:match("^mutex") then
              local id = itype
              local id_str = arg:match("%.(%d+)")
              if id_str then
                id = assert(tonumber(id_str))
              end
              str = "mutex " .. id .. ":" .. param
            elseif arg == "filter" then
              local param2 = influence["_Param" .. (i + 1)]
              local param3 = influence["_Param" .. (i + 2)]
              if param == 0 and param2 == 0 and param3 == 0 then
                -- nothing
              elseif param == 0 and param2 ~= 0 then
                str = class.get_name_p(param2)
                if param3 ~= 0 then
                  str = str .. ", " .. class.get_name_p(param3)
                end
              elseif param == 1 and param2 == 1 and param3 == 0 then
                str = "(rarity restriction)"
              elseif param == 1 and param2 == 2 and param3 == 0 then
                str = "Melee"
              elseif param == 1 and param2 == 5 then
                str = unit.get_name(param3)
              elseif param == 1 and param2 == 6 then
                str = rarity.get_name(param3)
              elseif param == 2 and param2 == 0 and param3 == 0 then
                str = "Dwarf/Elf"
              elseif param == 3 and param2 == 0 and param3 == 0 then
                str = "Rider"
              elseif param == 4 and param2 == 0 and param3 == 0 then
                str = "Magical"
              elseif param == 5 and param2 == 0 and param3 == 0 then
                str = "Dragon"
              else
                str = "?"
              end
              stop = true
            elseif arg:match("^enum%.") then
              local enum_name = assert(arg:match("%.(.*)$"))
              local enum = assert(enums[enum_name])
              str = (enum[param] or "?") .. " (" .. param .. ")"
            elseif arg:match("^format%.") then
              local replace_str = assert(arg:match("%.(.*)$"))
              str = replace_str:gsub("%%1", tostring(param), 1)
            end
            if str ~= "" then
              if not first then
                out = out .. ", "
              end
              out = out .. str
              first = false
            end
          end
        end
      else
        out = out .. "\tID " .. itype .. ":"
      end
      out = out .. " (" .. params .. ")\n"
      for _, str in ipairs(post) do
        out = out .. "\t  Detail:\n"
        out = out .. "\t    " .. str:gsub("\n(.)", "\n\t    %1")
      end
      local invoke = influence._InvokeType
      local target = influence._TargetType
      invoke = invoke_lookup[invoke] or invoke
      target = target_lookup[target] or target
      out = out .. "\t  Invoke: " .. invoke .. "; Target: " .. target .. "\n"
      
      local function add_notes(command)
        for classes in command:gmatch("IsClassType%(([%d,%s]+)%)") do
          for id in classes:gmatch("%d+") do
            id = assert(tonumber(id))
            out = out .. "\t    Note: class " .. id .. " is \"" .. class.get_name_p(id) .. "\"\n"
          end
        end
        for cards in command:gmatch("IsCardID%(([%d,%s]+)%)") do
          for id in cards:gmatch("%d+") do
            id = assert(tonumber(id))
            out = out .. "\t    Note: card " .. id .. " is \"" .. unit.get_name(id) .. "\"\n"
          end
        end
        for gender in command:gmatch("GetGender%(%)%s*%=%=%s*(%d+)") do
          gender = assert(tonumber(gender))
          if enums.gender[gender] then
            out = out .. "\t    Note: gender " .. gender .. " is " .. enums.gender[gender] .. "\n"
          end
        end
        for rare in command:gmatch("IsRaryty%((%d+)%)") do
          rare = assert(tonumber(rare))
          out = out .. "\t    Note: rarity " .. rare .. " is \"" .. rarity.get_name(rare) .. "\"\n"
        end
        if command:match("GetClassID%(%)%s*%<%s*10000") then
          out = out .. "\t    Note: classes less than 10000 are melee classes\n"
        end
        if command:match("GetClassID%(%)%s*%>%=%s*10000") then
          out = out .. "\t    Note: classes greater than or equal to 10000 are ranged classes\n"
        end
      end
      
      if influence._Command and influence._Command ~= "" then
        out = out .. "\t  Command: " .. influence._Command .. "\n"
        add_notes(influence._Command)
      end
      if influence._ActivateCommand and influence._ActivateCommand ~= "" then
        out = out .. "\t  Command (Activate): " .. influence._ActivateCommand .. "\n"
        add_notes(influence._ActivateCommand)
      end
      if stop then
        break
      end
    end
  end
  return out
end

return {
  parse = parse,
  parsewiki = parsewiki,
  parse_config = parse_config,
}
