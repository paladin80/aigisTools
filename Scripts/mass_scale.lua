-- mass_scale.lua (add-on)
-- author: illumin9
-- 
-- usage: do mass_scale.lua [cards or stand (optional)]
-- note: only works after you have downloaded one or more characters' 
--  full set of sprites via get_unit.lua or download_all.lua. Outputs
--  the nudged and/or scaled versions of all current units's sprites
--  in their respective folders.

local gm_lib = require("lib/gm")
local file = require("lib/file")
local scale_lib = require("lib/scale_calcs")
local xmldoc = require("lib/xmldoc")
local xml = require("lib/xml")
local working = "working\\" -- not that I actually used the variable itself, but I did use the folder
local pngout_path = "Utilities\\pngout.exe"
local has_pngout = file.file_exists(pngout_path)
local mode, force, option = ...
if not option then option = "" end
local unit_scale = option:match('[%d%.]+')

-- card info get
local text = xmldoc.getfile(nil, 'cards')
local obj = xml.parse(text)
local t = xml.totable(obj)
local scale_list = {}
local count = #t
for n = 1, count do
  scale_list[t[n]['CardID']] = t[n]['DotScale']
end
-- print(scale_list[1])
-- print(scale_list[95])

--[[
io.write("\nBy default, this script assumes a Windows OS; if\n")
io.write("not, please type 'lua' without quotation marks.\n")
io.flush()
ou_es = io.read() ]]

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

-- targets folder out/files/PlayerDotStand(.aar),
--   places into out/processed_files/PlayerDotStand(.aar)
if mode:match("stand") then
  local stand = "out\\files\\"
  local out_stand = "out\\proccessed_files\\"
  if not file.dir_exists(out_stand) then
    file.make_dir(out_stand)
  end
  if file.dir_exists(stand.."PlayerDotStand\\")then
    out_stand = stand .. "PlayerDotStand_Scaled"
    if unit_scale then out_stand = out_stand .. '_' .. unit_scale end
    out_stand = out_stand .. '\\'
    if not file.dir_exists(out_stand) then
      file.make_dir(out_stand)
    end
    stand = stand .. "PlayerDotStand\\"
  elseif file.dir_exists(stand.."PlayerDotStand.aar\\") then
    out_stand = stand .. "PlayerDotStand.aar_Scaled"
    if unit_scale then out_stand = out_stand .. '_' .. unit_scale end
    out_stand = out_stand .. '\\'
    if not file.dir_exists(out_stand) then
      file.make_dir(out_stand)
    end
    stand = stand .. "PlayerDotStand.aar\\"
  end
  if assert(stand:match("PlayerDotStand")) then
    local sep_list = search_dir(stand)
    for _, foudaa in ipairs(sep_list) do
      working_folder = stand .. foudaa .. "\\frames\\"
      out_working_folder = out_stand .. foudaa
      if not file.dir_exists(out_working_folder) then
        file.make_dir(out_working_folder)
      end
      out_working_folder = out_working_folder .. "\\frames\\"
      if not file.dir_exists(out_working_folder) then
        file.make_dir(out_working_folder)
      end
      local pics_list = search_png(working_folder)
      for _, pic in ipairs(pics_list) do
        local file_path = working_folder .. pic
        local scale_file_path = out_working_folder .. pic:sub(1,-5) .. "_scaled.png"
        if force == "force" or not file.file_exists(scale_file_path) then
          local unitID = tonumber(pic:sub(1,pic:find('_')-1))
          unit_scale = unit_scale or scale_list[unitID % 1808]
          scale_lib.do_scale(file_path, unit_scale, out_working_folder)
          if has_pngout then
            os.execute(pngout_path .. " " .. scale_file_path)
          end
        end
      end
    end
  end
end

-- targets folder out/cards, places into new folders
--   in same location
if mode:match('card') then
  local todo_units = {}
  for unitnum in mode:gmatch("%d+") do
    todo_units[tonumber(unitnum)] = true
  end
  local cards = "out\\cards\\"
  local unitslist = search_dir(cards)
  if assert(unitslist) ~= {} then for _, unit_num in ipairs(unitslist) do
    if todo_units == {} or todo_units[tonumber(unit_num)] then
      local unit_folder = cards .. unit_num .. "\\"
      local cclist = search_dir(unit_folder)
      if assert(cclist) ~= {} then for _, cc_num in ipairs(cclist) do
        local cc_folder = unit_folder .. cc_num .. "\\"
        local action_list = search_dir(cc_folder)
        if assert(action_list) ~= {} then for _, action in ipairs(action_list) do
          local action_folder = cc_folder .. action .. "\\"
          -- no assertion here because lack of ALMT.txt means not original
          --   (i.e. non-adjusted, non-scaled) folder
          if file.file_exists(action_folder .. "ALMT.txt") then
            local dimensions = {left = 0, top = 0, right = 0, bottom = 0}
            local pics_list = search_png(action_folder)
            -- collating origins to adjust to appropriate size
            for _, pic in ipairs(pics_list) do
              local pfile = io.popen('gm identify ' .. action_folder .. pic)
              local widxhei = pfile:read('*a')
              assert(pfile:close())
              local wid, hei = widxhei:match("PNG (%d+)x(%d+)%+0%+0")
              wid = tonumber(wid); hei = tonumber(hei)
              local teh_file = assert(io.open(action_folder .. pic:sub(1,-4) .. "txt", 'rb'))
              local file_content = teh_file:read('*a')
              assert(teh_file:close())
              local originx, originy = file_content:match("origin_x:(%d+).+origin_y:(%d+)")
              originx = tonumber(originx); originy = tonumber(originy)
              local right = wid - originx
              local bottom = hei - originy
              if dimensions["left"] < originx then dimensions["left"] = originx end
              if dimensions["top"] < originy then dimensions["top"] = originy end
              if dimensions["right"] < (wid - originx) then dimensions["right"] = (wid - originx) end
              if dimensions["bottom"] < (hei - originy) then dimensions["bottom"] = (hei - originy) end
            end
            local nudge_directory = action_folder .. 'nudged\\'
            if not file.dir_exists(nudge_directory) then file.make_dir(nudge_directory) end
            local scale_directory = action_folder .. 'scaled'
            if unit_scale then scale_directory = scale_directory .. '_' .. unit_scale end
            scale_directory = scale_directory .. '\\'
            if not file.dir_exists(scale_directory) then file.make_dir(scale_directory) end
            os.execute('gm convert -size ' .. dimensions["left"] + dimensions["right"] ..
              'x' .. dimensions["top"] + dimensions["bottom"] .. ' xc:none working\\background.miff')
            for _,pic in ipairs(pics_list) do
              local file_path = action_folder .. pic
              local result_path = nudge_directory .. pic
              if force == "force" or not file.file_exists(scale_directory .. pic:sub(1,-5) .. '_scaled.png') then
                local teh_file = assert(io.open(file_path:sub(1,-4) .. "txt", 'rb'))
                local file_content = teh_file:read('*a')
                assert(teh_file:close())
                local originx, originy = string.match(file_content,"origin_x:(%d+).+origin_y:(%d+)")
                local geometry = '-geometry +' .. dimensions["left"] - tonumber(originx) .. '+' .. dimensions["top"] - tonumber(originy) .. ' '
                assert(file.file_exists('working\\background.miff'))
                os.execute('gm composite ' .. geometry .. file_path .. ' working\\background.miff ' .. result_path)
                if has_pngout then
                  os.execute(pngout_path .. ' ' .. result_path)
                end
                unit_scale = unit_scale or scale_list[tonumber(unit_num)]
                scale_lib.do_scale(result_path, unit_scale, scale_directory)
              end
              if has_pngout then
                os.execute(pngout_path .. ' ' .. scale_directory .. pic:sub(1,-5) .. '_scaled.png')
              end
            end
          end
          if not option:match('keepnudge') and file.dir_exists(action_folder .. 'nudged\\') then
            os.execute('rmdir ' .. action_folder .. 'nudged\\ /s /q')
          end
        end --[[for action_list]] end --[[for action_list]]
      end --[[for cclist]] end --[[if cclist]]
    end
  end --[[for unitslist]] end --[[if unitslist]]
  -- don't forget to use gm to adjust size of each sprite's dimensions
  -- before scaling up here
end
