-- parse_enemy.lua
-- v1.0
-- original author: lzlis
-- further alterations by illumini9
-- ...I can totally call this v1.1 by this point, can't I?

local dl = require("lib/download")
local parse = require("lib/parse_al")

local enemy_table_name = "Enemy.atb"
local enemy_id, opt, num = ...
if not num then num = 1 end
local reproduce, table_num

assert(enemy_id:match('%d+/'), "Improper format: no slash to indicate mission ID.")

if enemy_id:match("r%d+/%d+") then
  reproduce, enemy_id = enemy_id:match("r(%d+)/(%d+)")
  reproduce = string.format("%06d", tonumber(reproduce))
elseif enemy_id:match("%d+/%d+") then
  table_num, enemy_id = enemy_id:match("(%d+)/(%d+)")
  enemy_table_name = string.format("Enemy%06d.atb", table_num)
elseif enemy_id:match("r%d+/") then -- adding capability to take all enemy stats
  reproduce = enemy_id:match("r(%d+)/")
  reproduce = string.format("%06d", tonumber(reproduce))
elseif enemy_id:match("%d+/") then
  table_num = enemy_id:match("(%d+)/")
  enemy_table_name = string.format("Enemy%06d.atb", table_num)
end

local event_id
if not enemy_id:match("%d+/") then
  event_id = assert(tonumber(reproduce or table_num))
  enemy_id = assert(tonumber(enemy_id))
else
  event_id = assert(tonumber(enemy_id:match("(%d+)/")))
  enemy_id = nil
end

local gfx_names = {}
local f_gfx_names = assert(io.open("Data/meta/enemy_gfx.txt", 'r'))
local i = 1
for l in f_gfx_names:lines() do
  gfx_names[i] = l
  i = i + 1
end
assert(f_gfx_names:close())


--[[local files = {    -- it doesn't *look* like this was needed. Gets overwritten before it's used, and
  --"EnemyStory1.aar", --  EnemyReproduce.aar wasn't a real file anyway. - illumini9
  --"EnemyEvent.aar",
  "EnemyReproduce.aar",
  --"EnemyDaily.aar",
  --"EnemyDot0484.aar",
}]]

local files_text = {}
local enemy_table = nil
local getfiles = false
if reproduce then
  reproduce = dl.getfile(nil, "Reproduce" .. reproduce .. ".aar")
  reproduce = parse.parse(reproduce)
  for _, archfile in ipairs(reproduce) do
    if archfile.name:match("EnemyReproduce%d+%.aar") then
      files_text[archfile.name] = archfile.value
    elseif archfile.name:match("Enemy%d+%.atb") then
      enemy_table = archfile.value
    end
  end
else
  getfiles = true
end

local text
local enemies
if enemy_table then
  enemies = enemy_table
else
  text = dl.getfile(nil, enemy_table_name)
  enemies = parse.parse(text)
end

local enemy_ids = {}
if enemy_id then
  enemy_ids = { enemy_id }
else
  for ID, contents in ipairs(enemies) do
    table.insert(enemy_ids, ID)
  end
end

local kAttributeArmored = "アーマー"
local kAttributeUndead = "アンデッド"
local kAttributeStealth = "ステルス"
local attributeMap = {
  [kAttributeArmored] = "Armored",
  [kAttributeUndead] = "Undead",
  [kAttributeStealth] = "Stealth",
}

local types = { -- moving all the lookups outside the loop to avoid multiple creation during loops.
  [1] = "Armored", -- I'm probably being a bit pedantic here though. -illumini9
  [2] = "Dragon",
  [3] = "Demon",
  [4] = "Youkai",
  [5] = "Golem",
  [6] = "Angel",
  [7] = "Merfolk",
  [8] = "Orc",
  [9] = "Goblin",
  [10] = "Giant",
  [11] = "Beast",
  [12] = "Beastman",
  [13] = "Hellbeast",
  [14] = "[[Bewitching Beast]]",
  [15] = "[[Divine Beast]]",
  [16] = "Human",
  [17] = "[[Giant God]]",
  [18] = "Insect",
  [19] = "God",
  [20] = "Celestial",
}

local lookup_attribute = {
  [1] = "Undead",
  [2] = "Stealth",
}

local lookup_effects = {
  --[1] = ??? this is on some of the crystal guardians
  [2]  = "Paralyze (Roper ver.)", -- Param2 seems to be divided by 500 for time (6000 on influence 240, lasts approx 12s, see below)
  [3]  = "Yurina(?)", 
  [4]  = "Has aura",
  [5]  = "Has aura, attack multiplier goes up with HP loss (Avenger ver.)", -- Dark Elf Avenger
  [6]  = "Ranged attacks do half damage (Magic Fencer)", -- Half damage at range
  [7]  = "Multishot", -- Param1 = No. Shots; See Nanaly
  [8]  = "Multitarget", -- Param1 = No. Targets; See War Elephant
  [9]  = "Does not stop to attack.", -- See Goblin Queen, Gazer, Blue Gazer
  [10] = "Attack five times",
  [11] = "Does not stop to attack",
  [12] = "Shadow (Minotaur)", -- Minotaur special
  [13] = "Shadow Caster (Minotaur)", -- Minotaur special
  [14] = "Attacks all in range",
  [15] = "Paralyze (Vampire ver.)",
  [16] = "Degeneration", -- http://aigis.wikia.com/wiki/Talk:Majin_Phenex%27s_Advent/@comment-Urizithar-20170501152643/@comment-Lzlis-20170501214656?permalink=14524#comm-14524
  [17] = "Has aura and attacks twice(?)",
  [18] = "Area of Effect", -- Param1 = ??; Param2 = Range (DOUBLE THIS FOR ACTUAL VALUE); Param3 = Tick Rate (Frames); [Pairs with many others (19, 20, 35, etc) see War Rat, Majin Belzebuth, see Kimaris' Servant for range]
  [19] = "DoT", -- Param2 = True damage per tick
  [20] = "ATK Debuff", -- Allies in range have ATK% set to Param1
  [21] = "DEF Debuff", -- Allies in range have DEF% set to Param1 (?)
  [22] = "MR Debuff", -- Allies in range have MR% set to Param1
  [23] = "Explode(100%)", -- Counterattack/Retaliation, Param2 = % of ATK dealt as true damage. See Furfur
  [24] = "Retreats", -- Emilia (M1)
  [25] = "Damage Taken Multi", -- Param1 = %, see Vepar Ninjas (300107/31)
  [26] = "Dark Knight effect: debuffs attack", -- Year End Gold Rush version
  [28] = "Dark Knight effect: debuffs attack, self HP loss",
  [30] = "Has aura and attacks all in range", -- Anelia
  [32] = "Regeneration", -- http://aigis.wikia.com/wiki/Talk:Majin_Phenex%27s_Advent/@comment-Urizithar-20170501152643/@comment-Lzlis-20170501214656?permalink=14524#comm-14524
  -- 34+ are in the config file
  [35] = "Enemy AoE Attack Multi", -- Makai Referee
  [36] = "EnemyAoE Defense Multi", -- Kimaris' Servant
  [46] = "Has aura and regenerates", -- Spirit Rescue G - (60/30000)?
  [47] = "Has aura and regenerates", -- Spirit Rescue G Gold Werewolf - (400/30000)?
  [54] = "50% physical dodge",
  [204] = "Avenger, 50% ATKx3, 25% ATKx5",
  [214] = "Has aura and hits twice", -- Maou Garius
  [216] = "Multitarget 3", -- War Elephant
  [220] = "Paralyze, 6hits, 12s, no block", -- Girtablilu, Golden Scorpion
  [232] = "Attacks all units within range.",
  [233] = "Paralyze, 6 hits, ?s",
  [240] = "Paralyze, 1 hit, 12s", -- Vampire Princess, https://www.youtube.com/watch?v=Fu8yLSr4nww
}

local lookup_Param_Change = {
  [1] = {"Melee", "melee"},
  [2] = {"Death", "death"},
  [3] = {"50%", "50% health"},
  [4] = {"Attack", "being attacked"},
  [5] = {"99%", "99% health"},
}

-- preload in order to avoid loading every loop - illumini9
local missiles = dl.getfile(nil, "Missile.atb")
missiles = parse.parse(missiles)

local group_rows = dl.getfile(nil, "GroupConfig.atb")
group_rows = parse.parse(group_rows)
group_rows = parse.totable(group_rows)

-- missile deflect data
local deflectable = {}
for _, row in ipairs(group_rows) do
  local id = row.MissileID_Reflection
  if id ~= 0 then
    deflectable[id - 1] = true
  end
end
-- end missile deflect data
-- end preload

local function background_calcs(en_id)
  local enemy = assert(enemies[en_id])
  
  for idx, field in ipairs(enemy) do
    local head = enemies.header.object[idx]
    enemy[head.name_en] = field.v
  end

  enemy.Attributes = {}
  if type(enemy._Attribute) == "string" then
    for attrb in enemy._Attribute:gmatch("[^,]+") do
      enemy.Attributes[attrb] = true
    end
  end

  local files
  local dotnum = (enemy.PatternID - 0x200000) // 0x100
  local dotarch_name = string.format("EnemyDot%04d.aar", dotnum)
  if dl.listhasfile(nil, dotarch_name) then
    files = {dotarch_name}
  end

  if getfiles then
    for _, file in ipairs(files) do
      files_text[file] = dl.getfile(nil, file)
    end
  end

  -- option for using or not "fast" mode, which would then abstain from looking at the sprite's frame data/speed
  -- ...does "fast" stand for "frame attack speed time"? -illumini9
  local arch_map = {}

  if not fast then
    
    for file, text in pairs(files_text) do
      local pattern_map = {}
      
      if reproduce then
        print(file)
      end
      
      local archive
      if type(text) == "string" then
        archive = parse.parse(text)
      else
        archive = text
      end
      
      for _, archfile in ipairs(archive) do
        if archfile.name == "Attack.aod" then
          assert(archfile.value.type == "ALOD")
          local pattern = archfile.value.mt and archfile.value.mt.pattern
          if pattern then
            pattern = pattern & ~0xff
            --print(string.format("found pattern %x", pattern))
            assert(pattern_map[pattern] == nil)
            pattern_map[pattern] = archfile.value
          end
        end
      end
      
      pattern_map.textures = archive.textures
      assert(pattern_map.textures)
      
      arch_map[file] = pattern_map
      
      if not reproduce then -- what are the "reproduce" files anyway? Don't think
        files_text[file] = nil -- I've seen a case of that yet. -illumini9
      end
    end
    
  end
  -- end of non-"fast" mode

  -- missiles data
  local missile = assert(missiles[enemy.MissileID + 1])
  for idx, field in ipairs(missile) do
    local head = missiles.header.object[idx]
    missile[head.name_en] = field.v
  end
  -- end missiles data
  
  return enemy, arch_map, missile
end

local fast = opt and opt:match("fast")
if opt and opt:match("enemylist") then
  
  local file_lib = require("lib/file")
  local process_out = "out\\proccessed_files\\"
  if not file_lib.dir_exists(process_out) then
    file_lib.make_dir(process_out)
  end
  process_out = process_out .. "parse_enemy\\"
  if not file_lib.dir_exists(process_out) then
    file_lib.make_dir(process_out)
  end
  local liststart = "{{Enemylist start}}\n<onlyinclude>{{{{{format|Enemylist item}}}\n"
  local listend = "}}</onlyinclude>\n{{Enemylist end}}"
  local regular_extras1 = string.format("|v{{{%d|%d}}}AdditionalNotes={{{additionalNotes{{{%d|%d}}}|}}}\n",num,num,num,num) -- necessary? -illumini9
  local regular_extras2 = string.format("|v{{{%d|%d}}}Scaling={{{scaling{{{%d|%d}}}|1}}}\n",num,num,num,num)
  local other_extras1 = string.format("|v{{{%d|%d}}}HpBonus={{{hpBonus{{{%d|%d}}}|1}}}\n",num,num,num,num)
  local other_extras2 = string.format("|v{{{%d|%d}}}AtkBonus={{{atkBonus{{{%d|%d}}}|1}}}\n",num,num,num,num)
  local other_extras3 = string.format("|v{{{%d|%d}}}DefBonus={{{defBonus{{{%d|%d}}}|1}}}\n",num,num,num,num)
  local other_extras4 = string.format("|v{{{%d|%d}}}RangeBonus={{{rangeBonus{{{%d|%d}}}|1}}}\n",num,num,num,num)
  local other_extras5 = string.format("|v{{{%d|%d}}}MoveBonus={{{moveBonus{{{%d|%d}}}|1}}}\n",num,num,num,num)
  for _, en_id in ipairs(enemy_ids) do
    local enemy, arch_map, missile = background_calcs(en_id)

    local dotscale = enemy.DotRate
    local range = enemy.ATTACK_RANGE
    local gfx_index = (enemy.PatternID - 0x00200000) // 0x100
    
    local meat = ''
    
    local name = gfx_names[gfx_index]
    if not name or name == "/?" then name = "<!-- name here -->" end
    meat = meat .. string.format("|name=%s {{{nameNotes|}}}\n|image=[[File:%s Sprite.png]]\n", name, name)
    meat = meat .. string.format("|v{{{%d|%d}}}ID=%6d/%-3d|v{{{%d|%d}}}frameID=%d\n",num,num,event_id,en_id,num,num,gfx_index)
    
    local enemyType = ""
    --[[
    if enemy.BossFlag ~= 0 then
      enemyType = enemyType .. "BOSS! "
    end]]
    --[[
    if enemy.Attribute ~= 0 then
      print("ATTRB", lookup_attribute[enemy.Attribute] or "ID:" .. enemy.Attribute)
    end
    for attrb, _ in pairs(enemy.Attributes) do
      print("ATTRB", attributeMap[attrb] or attrb)
    end]]
    if enemy.Attribute == 1 or enemy.Attributes[kAttributeUndead] then
      enemyType = enemyType .. "Undead "
    end
    if enemy.Attributes[kAttributeArmored] then
      enemyType = enemyType .. "Armored "
    end
    if enemy.Type > 0 then
      enemyType = enemyType .. (types[enemy.Type] or "ID:"..enemy.Type) .. " "
    end
    if enemyType ~= "" then
      meat = meat .. string.format("|v{{{%d|%d}}}Type=%s\n",num,num,enemyType:sub(1,-2))
    end
    
    local is_ranged, is_flying, is_passive, proj_spd = "no", "no", "no", ""
    if range > 0 then
      is_ranged = "yes"
      proj_spd = tonumber(missile.Speed)
      if math.floor(math.abs(proj_spd - math.floor(proj_spd + 0.5)) * 10 + 0.5) == 0 then
        proj_spd = math.floor(proj_spd + 0.5)
      end
      proj_spd = tostring(proj_spd)
    end
    if enemy.SkyFlag ~= 0 then
      is_flying = "yes"
    end
    meat = meat .. string.format("|v{{{%d|%d}}}IsRanged=%-4s|v{{{%d|%d}}}IsFlying=%-4s|v{{{%d|%d}}}IsPassive=%s\n",
                                 num, num, is_ranged, num, num, is_flying, num, num, is_passive)
    
    local true_range = assert(tostring(math.floor(range * dotscale / 1.5 + 0.5)), "Range scaling fail")
    if true_range == "0" then true_range = "" end
    meat = meat .. string.format("|v{{{%d|%d}}}Hp=%-10d|v{{{%d|%d}}}Range=%-7s|v{{{%d|%d}}}UP=%d\n",
                                 num, num, enemy.HP, num, num, true_range, num, num, enemy.GainCost or 1)
    
    local atk_count = "" -- how to figure this out...
    local is_magic_attack = enemy.MagicAttack ~= 0 and "yes" or "no"
    meat = meat .. string.format("|v{{{%d|%d}}}Atk=%-9d|v{{{%d|%d}}}AtkCount=%-4s|v{{{%d|%d}}}IsMagicAttack=%-4s|v{{{%d|%d}}}Splash=",
                                 num, num, enemy.ATTACK_POWER, num, num, atk_count, num, num, is_magic_attack, num, num)
    
    if missile.DamageArea > 0 then
      meat = meat .. string.format("%.2f", missile.DamageArea * 4 / 3)
    end
    
    local assassination_rate, rate_decimal = string.match(tostring(enemy.Param_ResistanceAssassin/1000),"(%d+)%.(%d+)")
    if not (tonumber(rate_decimal) == 0) then assassination_rate = assassination_rate .. '.' .. rate_decimal end
    meat = meat .. string.format("\n|v{{{%d|%d}}}Def=%-9d|v{{{%d|%d}}}MR=%-10d|v{{{%d|%d}}}AssassinationRate=%s\n",
                                 num, num, enemy.ARMOR_DEFENSE, num, num, enemy.MAGIC_DEFENSE, num, num, assassination_rate)
    
    local atk_spd, atk_init, atk_move = "", "", ""
    
    local attack_frame = enemy.AttackAnimNo -- starting here is the section on attack speed. Using
    --                                          "fast" mode skips frame analysis and checks just
    local found = false --                      the enemy table atb file, if I'm interpreting right. -illumini9
    local pattern = enemy.PatternID
    --print(string.format("need pattern %0x", pattern))
    if pattern then
      for arch_name, pattern_map in pairs(arch_map) do
        --[[ local where = "enemy_gfx\\" .. arch_name .. "\\" -- commented these out since it looks
        if aod then --                                            like they aren't used - illumini9
        
        end]]
        
        local aod = pattern_map[pattern]
        for p, aod in pairs(pattern_map) do
          if p == pattern then
            if aod.mt and aod.mt.entries[1] and aod.mt.entries[1].data and aod.mt.entries[1].data.PatternNo then
              local ftimes = {}
              for _, f in ipairs(aod.mt.entries[1].data.PatternNo) do ftimes[#ftimes+1] = f.time end
              --print("FR", arch_name, aod.mt.length, table.unpack(ftimes))
              if range == 0 then
                atk_spd = tostring(1 + enemy.ATTACK_SPEED + aod.mt.length + 2 * enemy.AttackWait)
              else
                atk_spd = tostring(1 + aod.mt.length + 2 * enemy.AttackWait)
              end
              if aod.mt.entries[1].data.PatternNo[1 + attack_frame] then
                found = true
                atk_init = tostring(aod.mt.entries[1].data.PatternNo[1 + attack_frame].time) -- +1 is Lua-indexing offset
              else
                atk_init = "<!-- parse failed (1) -->"
              end
            else
              atk_init = "<!-- parse failed (2) -->"
            end
          end
        end
      end
    end
    
    if range > 0 then
      atk_move = tostring(enemy.AttackWait * 2 + 1)
    end
    
    if not found then
      if range > 0 then
        atk_spd = tostring(1 + enemy.ATTACK_SPEED + 2 * enemy.AttackWait) .. "<!-- inexact -->"
      else
        atk_spd = tostring(1 + 2 * enemy.AttackWait) .. "<!-- inexact -->"
      end
      atk_init = atk_init .. "<!--N/A-->"
    end
    
    meat = meat .. string.format("|v{{{%d|%d}}}AtkSpd=%-6s|v{{{%d|%d}}}AtkInit=%-5s|v{{{%d|%d}}}AtkMove=%-10s|v{{{%d|%d}}}ProjSpd=%s\n",
                                 num, num, atk_spd, num, num, atk_init, num, num, atk_move, num, num, proj_spd)

    meat = meat .. string.format("|v{{{%d|%d}}}Move=%d\n|v{{{%d|%d}}}Notes=", num, num, enemy.MOVE_SPEED, num, num)

    local notes = ""
    if enemy.ATTACK_TYPE ~= 0 then
      notes = notes .. "Attack type ID: %d" .. enemy.ATTACK_TYPE
    end
    
    if deflectable[enemy.MissileID] then
      if not (notes == "") then notes = notes .. "<br>" end
      notes = notes .. "Ranged attack undeflectable."
    end

    if missile.SlowTime > 0 or missile.SlowRate > 0 then
      if not (notes == "") then notes = notes .. "<br>" end
      notes = notes .. string.format("Slow: %.1f%% for %.2f seconds", missile.SlowRate, missile.SlowTime)
    end

    if enemy.SpecialEffect ~= 0 then
      if not (notes == "") then notes = notes .. "<br>" end
      notes = notes .. (lookup_effects[enemy.SpecialEffect] or ("Effect ID:" .. enemy.SpecialEffect))
    end

    if enemy.SKILL ~= 0 then
      if not (notes == "") then notes = notes .. "<br>" end
      notes = notes .. "Skill ID: " .. enemy.SKILL
    end

    if enemy.Weather ~= 0 then
      if not (notes == "") then notes = notes .. "<br>" end
      notes = notes .. "Weather effect ID:" .. enemy.Weather
    end

    if enemy.DeadEffect ~= 0 then
      if not (notes == "") then notes = notes .. "<br>" end
      notes = notes .. "Unique death animation."
      -- 1: Gold Armor, Gold Living Axe Armor
    end

    if enemy.Param_ChangeParam ~= 0 or enemy.Param_ChangeCondition ~= 0 then
      if not (notes == "") then notes = notes .. "<br>" end
      local change_condition
      if lookup_Param_Change[enemy.Param_ChangeCondition] then
        change_condition = lookup_Param_Change[enemy.Param_ChangeCondition][2]
      else
        change_condition = "condition #" .. enemy.Param_ChangeCondition
      end
      notes = notes .. string.format("Upon %s, transforms into stronger form.", change_condition)
    end

    if enemy.BgmID ~= 0 then
      if not (notes == "") then notes = notes .. "<br>" end
      notes = notes .. "Prompts BGM change."
    end
    
    if enemy_id then
      print(liststart)
      print(meat .. notes)
      print()
      print(regular_extras1 .. regular_extras2 .. other_extras1 .. other_extras2 .. other_extras3 .. other_extras4 .. other_extras5)
      print(listend)
    else
      local event_folder = process_out .. event_id .. "\\"
      if not file_lib.dir_exists(event_folder) then
        file_lib.make_dir(event_folder)
      end
      
      local h = assert(io.open(event_folder .. string.format("Enemy %03d.txt", en_id), "w"))
      h:write(liststart)
      h:write(meat .. notes)
      h:write('\n\n')
      h:write(regular_extras1 .. regular_extras2 .. other_extras1 .. other_extras2 .. other_extras3 .. other_extras4 .. other_extras5)
      h:write(listend)
      assert(h:close())
    end
  end
else
  for _, en_id in ipairs(enemy_ids) do
    local enemy, arch_map, missile = background_calcs(en_id)

    local dotscale = enemy.DotRate
    local range = enemy.ATTACK_RANGE
    local gfx_index = (enemy.PatternID - 0x00200000) // 0x100
    --if gfx_names[gfx_index] then
      print("GFX", gfx_names[gfx_index], "("..gfx_index..")")
    --end
    if range > 0 then
      print("range", range, range * dotscale / 1.5)
      print("pspd", missile.Speed, "deflect", deflectable[enemy.MissileID] and "y" or "n", "(MissileID)", enemy.MissileID)
    else
      print("melee")
    end
    local enemyType = ""
    if enemy.BossFlag ~= 0 then
      enemyType = enemyType .. "BOSS! "
    end
    if enemy.Attribute == 1 or enemy.Attributes[kAttributeUndead] then
      enemyType = enemyType .. "Undead "
    end
    if enemy.Attributes[kAttributeArmored] then
      enemyType = enemyType .. "Armored "
    end
    if enemy.SkyFlag ~= 0 then
      enemyType = enemyType .. "Flying "
    end
    if enemy.Type > 0 then
      enemyType = enemyType .. (types[enemy.Type] or "ID:"..enemy.Type) .. " "
    end
    if enemyType ~= "" then
      print("TYP", enemyType)
    end
    local dt = enemy.MagicAttack ~= 0 and "magic" or "physical"
    print("HP", enemy.HP)
    local attack = enemy.ATTACK_POWER .. " " .. dt
    if missile.DamageArea > 0 then
      attack = attack .. " splash " .. missile.DamageArea
    end
    print("ATK", attack)
    print("DEF", enemy.ARMOR_DEFENSE, "MR", enemy.MAGIC_DEFENSE, "AR", enemy.Param_ResistanceAssassin, "(" .. (enemy.Param_ResistanceAssassin/1000) .. ")")
    --print("MR", enemy.MAGIC_DEFENSE)
    --print("AR", enemy.Param_ResistanceAssassin)
    print()
    print("MOV", enemy.MOVE_SPEED)
    print("SCL", enemy.DotRate)
    print()
    local attack_frame = enemy.AttackAnimNo -- starting here is the section on attack speed. Using
    --                                          "fast" mode skips frame analysis and checks just
    local found = false --                      the enemy table atb file, if I'm interpreting right. -illumini9
    local pattern = enemy.PatternID
    --print(string.format("need pattern %0x", pattern))
    if pattern then
      for arch_name, pattern_map in pairs(arch_map) do
        --[[ local where = "enemy_gfx\\" .. arch_name .. "\\" -- commented these out since it looks
        if aod then --                                            like they aren't used - illumini9
        
        end]]
        
        local aod = pattern_map[pattern]
        for p, aod in pairs(pattern_map) do
          if p == pattern then
            if aod.mt and aod.mt.entries[1] and aod.mt.entries[1].data and aod.mt.entries[1].data.PatternNo then
              local ftimes = {}
              for _, f in ipairs(aod.mt.entries[1].data.PatternNo) do ftimes[#ftimes+1] = f.time end
              local str = arch_name .. " "
              --print("FR", arch_name, aod.mt.length, table.unpack(ftimes))
              if range == 0 then
                str = str .. "FAS ".. (1 + enemy.ATTACK_SPEED + aod.mt.length + 2 * enemy.AttackWait)
              else
                str = str .. "FAS ".. (1 + aod.mt.length + 2 * enemy.AttackWait)
              end
              if aod.mt.entries[1].data.PatternNo[1 + attack_frame] then
                found = true
                str = str .. " FIN " .. (aod.mt.entries[1].data.PatternNo[1 + attack_frame].time) -- +1 is Lua-indexing offset
              else
                str = str .. " FIN bad"
              end
              if range > 0 then
                str = str .. " FMV " .. (enemy.AttackWait * 2 + 1)
              end
              print(str)
            else
              print("FR", arch_name, "?")
            end
          end
        end
      end
    end

    if not found then
      print("AS", enemy.ATTACK_SPEED)
      print("AW", enemy.AttackWait, "MOVE", enemy.AttackWait * 2 + 1)
      print("AF", enemy.AttackAnimNo)
    end

    print()

    if enemy.ATTACK_TYPE ~= 0 then
      print("ATKTY", enemy.ATTACK_TYPE)
    end

    if missile.SlowTime > 0 or missile.SlowRate > 0 then
      print("SLOW", missile.SlowTime, missile.SlowRate .. "%")
    end

    if enemy.Attribute ~= 0 then
      print("ATTRB", lookup_attribute[enemy.Attribute] or "ID:" .. enemy.Attribute)
    end
    for attrb, _ in pairs(enemy.Attributes) do
      print("ATTRB", attributeMap[attrb] or attrb)
    end

    if enemy.SpecialEffect ~= 0 then
      print("EFF", lookup_effects[enemy.SpecialEffect] or "ID:" .. enemy.SpecialEffect)
    end

    if enemy.SKILL ~= 0 then
      print("SKILL", enemy.SKILL)
    end

    if enemy.Weather ~= 0 then
      print("WEATH", enemy.Weather)
    end

    if enemy.GainCost ~= 0 then -- gained when killed by Valkyrie or similar
      print("UP", enemy.GainCost)
    end

    if enemy.DeadEffect ~= 0 then
      print("DEATH", enemy.DeadEffect)
      -- 1: Gold Armor, Gold Living Axe Armor
    end

    if enemy.Param_ChangeParam ~= 0 or enemy.Param_ChangeCondition ~= 0 then
      local change_condition
      if lookup_Param_Change[enemy.Param_ChangeCondition] then
        change_condition = lookup_Param_Change[enemy.Param_ChangeCondition][1]
      else
        change_condition = "COND:" .. enemy.Param_ChangeCondition
      end
      print("CHANG", change_condition, "->", enemy.Param_ChangeParam)
    end

    if enemy.BgmID ~= 0 then
      print("BGM", enemy.BgmID)
    end
  end -- end for loop on enemy_id
end