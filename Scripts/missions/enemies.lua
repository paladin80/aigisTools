local dl = require("lib/download")
local parse_al = require("lib/parse_al")
local enemygfx_names

local function get_enemy_gfx_names()
  if not enemygfx_names then
    enemygfx_names = {}
    local h = assert(io.open("Data\\meta\\enemy_gfx.txt", "r"))
    local text = assert(h:read("*a"))
    assert(h:close())
    for name in text:gmatch("(%C*)\n\r?") do
      table.insert(enemygfx_names, name)
    end
  end
  return enemygfx_names
end

local function init_enemies()
  local text = dl.getfile(nil, "Enemy.atb")
  local enemies = parse_al.parse(text)
  local names = get_enemy_gfx_names()

  for idx in ipairs(enemies) do
    if names[idx] then
      enemies[idx]._name = names[idx]
    end
  end
  return enemies
end

return {
   init_enemies = init_enemies,
   get_enemy_gfx_names = get_enemy_gfx_names
}