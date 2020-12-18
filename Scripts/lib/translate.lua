local config = require "lookup//config"

local translate_url = nil
local translate_key = nil
local translate_init = false
local curlpath = [[curl]]

local function init_translate()
  translate_init = true
  if not config['Automatic translation'] then return end
  local h = io.open("Data/localisation/translate_keys.txt", "r")
  if h ~= nil then
    local text = assert(h:read("*a"))
    assert(h:close())
    for k,u in text:gmatch("(%C+)\n\r?(%C+)") do
      translate_key = k
      translate_url = u
      break
    end
  end
  if translate_key == nil then
    print "set translate key and url to use translation"
  end
end

local function escape(s)
  local chars = {}
  for i = 1, utf8.len(s) do
    local n = utf8.offset(s, i)
    local code = utf8.codepoint(s, n)
    table.insert(chars, code)
  end
  local result = '""' 
  for i, ch in pairs(chars) do
      result = result .. '\\u' .. string.format("%04x", ch)
  end
  return result .. '""'
end

local function translate(text)
  if not translate_init then
    init_translate()
  end
  if translate_url == nil or translate_key == nil then
    return nil
  else
    local request = escape(text)
    if (type(text) == "table") then
      request = ""
      for line in text do
        if string.len(request) > 0 then request = request.. ', ' end
        request = request .. escape(line)
      end
    end

    local cmd = curlpath .. ' -X POST --user "apikey:'.. translate_key .. '" --header "Content-Type: application/json" --data '
    cmd = cmd .. '"{""text"": [' .. request .. '], ""model_id"":""ja-en""}" '
    cmd = cmd .. translate_url .. "/v3/translate?version=2018-05-01"

    -- print(cmd)

    local h = assert(io.popen(cmd))
    local text = assert(h:read('*a'))
    h:close()
    local result = {}
    for tran in text:gmatch('"translation" *: *"(%C+)"') do
      table.insert(result, tran)
    end
    if (type(text) == "table") then
      return result
    else
      return result[1]
    end
  end
end

return {
  translate = translate
}