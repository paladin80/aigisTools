-- gif_make.lua (add-on)
-- author: illumini9
-- 
-- usage: do gif_make.lua ["space-separated list of unitIDs"] ["space-separated list of cclevels"] ["space-separated list of animation numbers"]
-- e.g.
-- do gif_make.lua -> makes gifs of all units and all animations currently in out/cards folder
-- do gif_make.lua noforce "020 423" -> makes gifs of only units 020 and 423 (Lilia and Totono)
-- do gif_make.lua noforce 020 2 1 -> makes a gif out of unit 020, AW, standing
-- do gif_make.lua noforce "" "" "6 8" -> makes a gif out of all units with skill stand and skill attack animations
-- (for CC level; 0 is base, 1 is CC, 2 is AW, 3 is AW2v1, and 4 is AW2v2)
-- (for animation numbers, 1 is stand, 3 is attack, 6 is skill stand, and 8 is skill attack)
-- note: attack animation isn't *really* accurate, since it should include
--  some idle animations for cooldown time too. For now I'm not sure of the
--  fine details yet and will just animate the sprites as-is.
-- note: only works after you have downloaded one or more characters' 
--  full set of sprites via get_unit.lua or download_all.lua. Scaled-
--  up versios only appear after using mass_scale.lua to scale up
--  the sprites. Outputs  the gifs of all current units in the
--  "out/cards" folder into their respective folders.

local gm_lib = require("lib/gm")
local file = require("lib/file")
local scale_lib = require("lib/scale_calcs")
local out = "out\\cards\\"
local force, unitlist, cclist, animate_list, speed = ...
if not speed or not speed:match('%d+') then speed = 'x60' else speed = 'x' .. speed:match('%d+') end
local ccdict = {
  [1] = "",
  [2] = "CC",
  [3] = "AW",
  [4] = "AW2v1",
  [5] = "AW2v2"
}

local function suffixer(cc,animate,oftwo)
  cc, animate = tonumber(cc:sub(-1)) + 1, tonumber(animate)
  local temp = ccdict[cc]
  if not oftwo then
    temp = temp:sub(1,3)
  end
  if cc > 2 and animate > 5 then
    temp = 'S' .. temp
  elseif animate > 5 then
    temp = temp .. '_Skill'
  end
  if temp ~= '' then
    temp = '_' .. temp
  end
  if animate % 5 == 3 then
    temp = temp .. "_Attack"
  end
  return temp
end

local function separate_num(line,func)
  local temp = {}
  if line and line ~= "" then
    for word in line:gmatch("%d+") do
      if func then
        temp[func(word)] = true
      else
        temp[word] = true
      end
    end
  end
  return temp
end

unitlist = separate_num(unitlist, function (word) return string.format("%03d", word) end)
cclist = separate_num(cclist, function (word) return 'dot' .. word end)
animate_list = separate_num(animate_list, function (word) return string.format("%02d", word) end)

local ou_es
local pfile

local function search_dir(directory)
  local i, t = 0, {}
  if ou_es == "lua" then
    pfile = io.popen('ls -1 -F "'..directory..'"')
    -- should output folders as "name/" and files with their extensions
    for filename in pfile:lines() do
      if filename:sub(-1) == "/" then
        i = i + 1
        t[i] = filename:sub(1,-2)
      end
    end
  else
    pfile = io.popen('dir "'..directory..'" /b /ad')
    -- /ad lists all directories; /a-d lists all entries except directories
    for filename in pfile:lines() do
      i = i + 1
      t[i] = filename
    end
  end
  pfile:close()
  return t
end

local function search_png(directory)
  local i, t = 0, {}
  if ou_es == "lua" then
    pfile = io.popen('ls -1 -F "'..directory..'"')
    -- should output folders as "name/" and files with their extensions
    for filename in pfile:lines() do
      if filename:sub(-4) == ".png" then
        i = i + 1
        t[i] = filename
      end
    end
  else
    pfile = io.popen('dir "'..directory..'"*.png /b /a-d')
    -- /ad lists all directories; /a-d lists all entries except directories
    for filename in pfile:lines() do
      i = i + 1
      t[i] = filename
    end
  end
  pfile:close()
  return t
end

unittemp = search_dir(out)
for _, unitID in ipairs(unittemp) do
  if next(unitlist) == nil or unitlist[unitID] then
    local unit_folder = out .. unitID .. '\\'
    local cctemp = search_dir(unit_folder)
    local oftwo = false
    if cctemp[4] == 'dot3' and cctemp[5] == 'dot4' then
      oftwo = true
    end
    for _, dot_num in ipairs(cctemp) do
      if next(cclist) == nil or cclist[dot_num] then
        local dot_folder = unit_folder .. dot_num .. '\\'
        local animate_temp = search_dir(dot_folder)
        for _, pose in ipairs(animate_temp) do
          if pose:sub(1,2) ~= "05" and next(animate_list) == nil or animate_list[pose:sub(1,2)] then
            local animate_folder = dot_folder .. pose  .. '\\'
            if file.file_exists(animate_folder .. 'ALMT.txt') then
              if not file.dir_exists(unit_folder .. 'gifs\\') then file.make_dir(unit_folder .. 'gifs\\') end
              h = assert(io.open(animate_folder .. 'ALMT.txt', 'rb'))
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
                local edited_folders = search_dir(animate_folder)
                for _, edited_folder in ipairs(edited_folders) do
                  local gifname = unitID .. suffixer(dot_num,pose:sub(1,2), oftwo) .. '_Sprite'
                  if edited_folder == 'nudged' then
                    gifname = gifname .. '_(unscaled).gif'
                  elseif edited_folder ~= 'scaled' then
                    gifname = gifname .. '_(' .. edited_folder .. ').gif'
                  else
                    gifname = gifname .. '.gif'
                  end
                  local ext
                  if edited_folder == 'nudged' then ext = '.png ' else ext = '_scaled.png ' end
                  if file.dir_exists(animate_folder .. edited_folder .. '\\') and #steps == #search_png(animate_folder..edited_folder .. '\\') then
                      if force == 'force' or not file.file_exists(animate_folder .. gifname) then
                      local args = 'magick -dispose previous -loop 0 '
                      for step, secs in ipairs(steps) do
                        if next(steps,step) ~= nil then
                          args = args .. '-delay ' .. secs .. speed .. ' ' .. animate_folder .. edited_folder .. '\\'
                          args = args .. 'alod_SP00_' .. string.format("%02d", step - 1) .. ext
                        end
                      end
                      args = args .. unit_folder .. 'gifs\\' .. gifname
                      os.execute(args)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
