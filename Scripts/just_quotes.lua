local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local file = require("lib/file")
local format = require("lib/format")
local xmldoc = require("lib/xmldoc")
local xml = require("lib/xml")

local cards = xmldoc.getfile(nil, 'cards')
cards = xml.parse(cards)
cards = xml.totable(cards)

local names = dl.getfile(nil, "NameText.atb")
names = parse_al.parse(names)
names = parse_al.totable(names)

local status = dl.getfile(nil, "StatusText.atb")
status = parse_al.parse(status)
status = parse_al.totable(status)

local tokens = dl.getfile(nil, "TokenUnitConfig.atb")
tokens = parse_al.parse(tokens)
tokens = parse_al.totable(tokens)
local tokens_check = {}
for _, token in ipairs(tokens) do
  tokens_check[token.Param_SummonUnit] = true
end

local process_out = "out\\proccessed_files\\"
if not file.dir_exists(process_out) then
  file.make_dir(process_out)
end
process_out = process_out .. "just_quotes\\"
if not file.dir_exists(process_out) then
  file.make_dir(process_out)
end

--getting Julian and Crave to tell us whether adjutant's implemented or not.
local adjutant = (cards[8].Flavor - cards[7].Flavor) == 8

for _, card in ipairs(cards) do
  local id = card.CardID
  local name = names[id]
  if name then
    name = name.RealName or name.Message
  end
  
  if name and name ~= "-" and (not tokens_check[id]) then
    local out = ""
    if card.LoveEv1 ~= 0 then
      out = out .. "Quotes:\n"
      local loves = {0, math.floor(card.LoveEv1 / 2), card.LoveEv1, 50, 60, 80, 100}
      for i, love in ipairs(loves) do
        out = out .. format.pad(love, 3) .. "%: " .. tostring(status[card.Flavor + i].Message):gsub("%s+", " ") .. "\n"
      end
      if adjutant then
        out = out .. "Adjutant quote: " .. tostring(status[card.Flavor + 8].Message):gsub("%s+", " ") .. "\n"
      end
    else
      out = out .. "Quote: " .. tostring(status[card.Flavor + 1].Message):gsub("%s+", " ") .. "\n"
    end
    
    if (card.Kind == 0 or card.Kind == 1) and (card.Rare > 0) then
      local last_space = name:reverse():find(" ")
      if not last_space then last_space = 0 end
      name = name:sub(-last_space+1)
    end
    local h = assert(io.open(process_out .. string.format("%03d_", id) .. name .. ".txt", "w"))
    h:write(out)
    assert(h:close())
  end
end