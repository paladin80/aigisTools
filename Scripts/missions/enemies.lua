local dl = require("lib/download")
local parse_al = require("lib/parse_al")

local function init_enemies()
  local text = dl.getfile(nil, "Enemy.atb")
  local enemies = parse_al.parse(text)

  -- legacy enemy names
  local h = assert(io.open("Data\\meta\\enemy_names.txt", "r"))
  text = assert(h:read("*a"))
  assert(h:close())

  local idx = 1
  for name in text:gmatch("(%C*)\n\r?") do
    if not enemies[idx] then enemies[idx] = {} end
    if #name > 0 then
      enemies[idx]._name = name
    end
    idx = idx + 1
  end

  return enemies
end

local function get_enemy_gfx_names()
  local enemygfx_names = {}
  local h = assert(io.open("Data\\meta\\enemy_gfx.txt", "r"))
  local text = assert(h:read("*a"))
  assert(h:close())
  for name in text:gmatch("(%C*)\n\r?") do
    table.insert(enemygfx_names, name)
  end
  return enemygfx_names
end

return {
   init_enemies = init_enemies,
   get_enemy_gfx_names = get_enemy_gfx_names
}