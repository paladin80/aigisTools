local dl = require("lib/download")
local tran = require("lib/translate")

local name_dictionary
local class_dictionary
local race_dictionary
local translate_dictionary
local AllAgesVersionSuffix = ""
local function Initialize()
  local Initialized = false
  if Initialized == false then
    Initialized = true
    if dl.listhasfile(nil, "001_card_0.png") then AllAgesVersionSuffix = "" else AllAgesVersionSuffix = "_iOS" end
  end
end

local function build_array(text)
  local temp = {}
    for key, value in text:gmatch('([^=]+)=([^%c]+)') do
    key = key:match("^%s*(.-)%s*$")
    value = value:match("^%s*(.-)%s*$")
    temp[key] = value
  end
  return temp
end

local function build_mono_array(text)
  local temp = {} local n = 1
    for value in text:gmatch('([^%c]+)') do
    value = value:match("^%s*(.-)%s*$")
    temp[n] = value:gsub(' ', '_')
    n = n + 1
  end
  return temp
end

local function load_loc(locale, mode)
  local loc_localisation = 'Data\\localisation\\'
  if mode ~= 'single' then
    h = io.open(loc_localisation..locale, 'r')
    local data = h:read('*a')
    io.close(h)
    return build_array(data)
  else
    h = io.open(loc_localisation..locale, 'r')
    local temp = {}
    for line in h:lines() do
      if #line<1 then line = ".*Unknown*." end
      table.insert(temp, line)
    end
    io.close(h)
    return temp
  end
end

local function class_locale(query, set, full)
 if not class_dictionary then class_dictionary =  load_loc('Class.txt') end
 if set then
  class_dictionary[query] = set:gsub(' ', '_')
 elseif full then
   return class_dictionary
 else
   if class_dictionary[query] == ".*Unknown*." then return nil else return class_dictionary[query] end
 end
end

local function name_locale(query, set, full)
  Initialize()
  if not name_dictionary then name_dictionary =  load_loc('Name.txt', 'single') end
  if set then
    name_dictionary[query] = set:gsub(' ', '_')
  elseif full then
    return name_dictionary
  else
    if name_dictionary[query] == ".*Unknown*." then
      return nil
    else
      if name_dictionary[query] then return name_dictionary[query]:gsub(' ', '_')..AllAgesVersionSuffix end
    end
  end
end

local function race_locale(query)
  if not race_dictionary then race_dictionary =  load_loc('Race.txt') end
  if race_dictionary[query] == ".*Unknown*." then return nil else return race_dictionary[query] end
end

local function translate(text)
  if not translate_dictionary then translate_dictionary =  load_loc('translate.txt') end
  if translate_dictionary[text] then
    return translate_dictionary[text]
  else
    local translated = tran.translate(text)
    if translated == nil then
      translated = text
    else
      translated = translated .. " (" .. text .. ")"
    end
    translate_dictionary[text] = translated
    local h = io.open('Data\\localisation\\translate.txt', 'a')
    h:write(text .. ' = ' .. translated .. '\n')
    io.close(h)
    return translated;
  end
end

return {
  class = class_locale,
  name = name_locale,
  race = race_locale,
  translate = translate,
  
  effects_ability = require('arrays\\Effects-Ability'),
  effects_skill = require('arrays\\Effects-Skill')
}