local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local format = require("lib/format")

local function init_terms()
  local text = dl.getfile(nil, "QuestTermConfig.atb")
  local term_config = parse_al.parse(text)
  term_config = parse_al.totable(term_config)

  local terms = {}
  local term_text = {}

  local config_id = 0
  for _, config in ipairs(term_config) do
    local id = config.ID_Config
    if id ~= 0 then
      config_id = id
    end
    assert(config_id ~= 0)
    local term = terms[config_id] or {}
    terms[config_id] = term
    table.insert(term, config)
  end
  
  local term_influence_lookup = {
    [2] = {name = "No healers", args = {"flag"}},
    [8] = {name = "Periodic HP loss to allies", args = {"_", "n", "delay"}},
    [9] = {name = "Initial HP reduction", args = {"percent"}},
    [11] = {name = "Enemy DEF mod", args = {"percent"}},
    [12] = {name = "Enemy movement speed mod", args = {"percent"}},
    [13] = {name = "Ally ATK mod", args = {"percent"}}, -- maybe swapped with 14?
    [14] = {name = "Ally DEF mod", args = {"percent"}}, -- maybe swapped with 13? 
    [15] = {name = "Enemy size mod", args = {"percent"}},
    [16] = {name = "Ally size mod", args = {"percent"}},
    [17] = {name = "Unit points don't regenerate"},
    [18] = {name = "Enemy ATK mod", args = {"percent"}},
    [19] = {name = "Enemy range mod", args = {"percent"}},
    [20] = {name = "Enemy HP mod", args = {"percent"}},
    [21] = {name = "Enemy MR mod", args = {"percent"}},
    [22] = {name = "Ally magic damage mod", args = {"percent"}},
    [24] = {name = "Allowed unit restriction"},
    [25] = {name = "Ally cost mod", args = {"percent"}},
    [26] = {name = "Makai Miasma: Ally ATK mod", args = {"percent"}}, -- maybe swapped with 27?
    [27] = {name = "Makai Miasma: Ally DEF mod", args = {"percent"}}, -- maybe swapped with 26?
    [30] = {name = "Makai Miasma: UP Gen mod", args = {"percent"}},
  }

  for term_id, term in pairs(terms) do
    local text = "Term properties: (term " .. term_id .. ")\n"
    for _, config in ipairs(term) do
      text = text .. "\t" .. format.format(term_influence_lookup, config.Type_Influence, {config.Data_Param1, config.Data_Param2, config.Data_Param3, config.Data_Param4})
      if config.Data_Expression and config.Data_Expression ~= "" then
        text = text .. "\t  Expression: " .. config.Data_Expression .. "\n"
        local notes = format.get_notes(config.Data_Expression)
        if notes ~= "" then
          text = text .. "\t  " .. format.indent(notes, "\t  ")
        end
      end
    end
    term_text[term_id] = text
  end
  return term_text
end

return init_terms