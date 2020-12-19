local dl = require("lib/download")
local tran = require("lib/translate")

local name_dictionary
local translate_dictionary = {}

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

local function load_loc(locale, mode)
  local loc_localisation = 'Data\\localisation\\'
  if mode ~= 'single' then
    local h = io.open(loc_localisation..locale, 'r')
    if not h then return {} end
    local data = h:read('*a')
    io.close(h)
    return build_array(data)
  else
    local h = io.open(loc_localisation..locale, 'r')
    local temp = {}
    for line in h:lines() do
      if #line<1 then line = ".*Unknown*." end
      table.insert(temp, line)
    end
    io.close(h)
    return temp
  end
end

local function translate(text, type)
  if not translate_dictionary[type] then 
    translate_dictionary[type] =  load_loc(type .. '.txt') 
  end
  local dictionary = translate_dictionary[type]
  if dictionary[text] then
    return dictionary[text]
  else
    local translated = tran.translate(text)
    if translated == nil then
      translated = "(T)" .. text
    else
      translated = "(T)" .. translated
    end
    dictionary[text] = translated
    local h = io.open('Data\\localisation\\' .. type .. '.txt', 'a')
    h:write(text .. ' = ' .. translated .. '\n')
    io.close(h)
    return translated;
  end
end

local function class_locale(query)
  return translate(query, 'Race')
end

local function race_locale(query)
  return translate(query, 'Race')
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

return {
  class = class_locale,
  name = name_locale,
  race = race_locale,
  translate = translate,
  
  effects_ability = require('arrays\\Effects-Ability'),
  effects_skill = require('arrays\\Effects-Skill')
}