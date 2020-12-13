local dl = require("lib/download")
local ParseAl = require("lib/parse_al")
local OutputAl = require("wiki/output_al")
local File = require("lib/File")
local Config = require "lookup//Config"
local ScaleLib = require("lib/scale_calcs")
local GmLib = require("lib/gm")
local DumpLoc = Config["dump directory"]
local Working = Config["working directory"]

local function GetSprites(UnitID, Args)
    local OutputFolder = "out\\Enemies\\" .. UnitID .. "\\"
    if not dl.listhasfile(nil, string.format("EnemyDot%04d.aar", UnitID)) then
        print(UnitID .. " not found.")
        return nil
    end
    local Dots = dl.getfile(nil, string.format("EnemyDot%04d.aar", UnitID))
    local Dots = ParseAl.parse(Dots)
    for i, Dot in pairs(Dots) do
        --if type(i) ~= "number" then print (i) end
        if type(i) == "number" and Dot.name:match(".aod") then
            for k, v in pairs(Dot) do
                OutputAl.output(
                    Dot.value,
                    OutputFolder .. string.format("%03d_%s\\", i, Dot.name),
                    Working,
                    {textures = Dots.textures}
                )
            end
        end
    end
    return OutputFolder
end

local function GetGifs(UnitID, Args)
    local UnitScale = 1.5
    local OutputFolder = "out\\Enemies\\" .. UnitID .. "\\"
    local unit_name = UnitID
    if GetSprites(UnitID, Args) == nil then
        return nil
    end

    if Config["iSet Startup Printouts"] then
        print("Starting " .. unit_name .. " gifs")
    end
    local cmd = assert(io.popen("cmd /c dir " .. OutputFolder .. " /b", "r"))
    local h = cmd:read("*a")
    cmd:close()
    local cmd = io.popen("cmd /C dir " .. OutputFolder .. " /B", "r")
    animlist = cmd:read("*a")
    cmd:close()
    for anim in animlist:gmatch("%d+_[%a%d_]+.aod") do
        local cmd = io.popen("cmd /C dir " .. OutputFolder .. "\\" .. anim .. " /B", "r")
        imagelist = cmd:read("*a")
        cmd:close()
        local action_folder = OutputFolder .. "\\" .. anim .. "\\"
        --[[if (anim:match("Stand") or anim:match("Damage")) and (mode["full"] or mode["image"] or mode["sprite"]) then
                    local anim_suffix = ""
                    if anim:match("Damage") then
                        anim_suffix = "_Death"
                    end
                    local sprite = imagelist:match("(alod_SP%d+_%d*.png)")
                    os.execute(
                        "cmd /c copy " ..
                            action_folder ..
                                sprite ..
                                    " " ..
                                    OutputFolder ..
                                            "\\images\\" ..
                                                unit_name ..
                                                    art_suffix_B[tonumber(dot:match("dot(%d*)"))] ..
                                                        anim_suffix .. "_Sprite.png >nul 2>&1"
                    )
                    scale_lib.do_scale(
                        OutputFolder ..
                            "\\images\\" ..
                                unit_name ..
                                    art_suffix_B[tonumber(dot:match("dot(%d*)"))] .. anim_suffix .. "_Sprite.png",
                        cards[id].DotScale
                    )
                    os.execute(
                        "cmd /c del " ..
                        OutputFolder ..
                                "\\images\\" ..
                                    unit_name ..
                                        art_suffix_B[tonumber(dot:match("dot(%d*)"))] ..
                                            anim_suffix .. "_Sprite.png >nul 2>&1"
                    )
                    os.execute(
                        "cmd /c rename " ..
                        OutputFolder ..
                                "\\images\\" ..
                                    unit_name ..
                                        art_suffix_B[tonumber(dot:match("dot(%d*)"))] ..
                                            anim_suffix ..
                                                "_Sprite_scaled.png " ..
                                                    unit_name ..
                                                        art_suffix_B[tonumber(dot:match("dot(%d*)"))] ..
                                                            anim_suffix .. "_Sprite.png >nul 2>&1"
                    )
                    if Config["pngout"] then
                        os.execute(
                            "cmd /c pngout " ..
                            OutputFolder ..
                                    "\\images\\" ..
                                        unit_name ..
                                            art_suffix_B[tonumber(dot:match("dot(%d*)"))] ..
                                                "_Sprite.png" .. png_suffix_sprite
                        )
                    end
                    if Config["File Printouts"] then
                        print(
                            unit_name ..
                                art_suffix_B[tonumber(dot:match("dot(%d*)"))] .. anim_suffix .. "_Sprite.png generated"
                        )
                    end
                end]]
        --Re-purposed illumini9's mass-resize and gif-make right about here.
        if File.file_exists(action_folder .. "ALMT.txt") then
            local dimensions = {left = 0, top = 0, right = 0, bottom = 0}
            -- collating origins to adjust to appropriate size
            for pic in imagelist:gmatch("(alod_SP%d+_%d+.png)") do
                local pFile = io.popen("gm identify " .. action_folder .. pic)
                local widxhei = pFile:read("*a")
                assert(pFile:close())
                local wid, hei = widxhei:match("PNG (%d+)x(%d+)%+0%+0")
                wid = tonumber(wid)
                hei = tonumber(hei)
                local teh_File = assert(io.open(action_folder .. pic:sub(1, -4) .. "txt", "rb"))
                local File_content = teh_File:read("*a")
                assert(teh_File:close())
                local originx, originy = File_content:match("origin_x:(%d+).+origin_y:(%d+)")
                --Cutoff for massive X/Y transforms which can cause massive slowdowns.
                if
                    (Config["GIF XY Cutoff"] and tonumber(originx) > Config["GIF XY Cutoff"]) or
                        (Config["GIF XY Cutoff"] and tonumber(originy) > Config["GIF XY Cutoff"])
                 then
                    break
                end
                originx = tonumber(originx)
                originy = tonumber(originy)
                local right = wid - originx
                local bottom = hei - originy
                if dimensions["left"] < originx then
                    dimensions["left"] = originx
                end
                if dimensions["top"] < originy then
                    dimensions["top"] = originy
                end
                if dimensions["right"] < (wid - originx) then
                    dimensions["right"] = (wid - originx)
                end
                if dimensions["bottom"] < (hei - originy) then
                    dimensions["bottom"] = (hei - originy)
                end
            end
            local nudge_directory = action_folder .. "nudged\\"
            if not File.dir_exists(nudge_directory) then
                File.make_dir(nudge_directory)
            end
            local scale_directory = action_folder .. "scaled"
            --if unit_scale then scale_directory = scale_directory .. '_' .. unit_scale end
            scale_directory = scale_directory .. "\\"
            if not File.dir_exists(scale_directory) then
                File.make_dir(scale_directory)
            end
            os.execute(
                "gm convert -size " ..
                    dimensions["left"] + dimensions["right"] ..
                        "x" .. dimensions["top"] + dimensions["bottom"] .. " xc:none working\\background.miff"
            )
            for pic in imagelist:gmatch("alod_SP%d+_%d+.png") do
                --print(pic)
                local File_path = action_folder .. pic
                local result_path = nudge_directory .. pic
                if force == "force" or not File.file_exists(scale_directory .. pic:sub(1, -5) .. "_scaled.png") then
                    local teh_File = assert(io.open(File_path:sub(1, -4) .. "txt", "rb"))
                    local File_content = teh_File:read("*a")
                    assert(teh_File:close())
                    local originx, originy = string.match(File_content, "origin_x:(%d+).+origin_y:(%d+)")
                    --Cutoff for massive X/Y transforms which can cause massive slowdowns.
                    if
                        (Config["GIF XY Cutoff"] and tonumber(originx) > Config["GIF XY Cutoff"]) or
                            (Config["GIF XY Cutoff"] and tonumber(originy) > Config["GIF XY Cutoff"])
                     then
                        break
                    end
                    local geometry =
                        "-geometry +" ..
                        dimensions["left"] - tonumber(originx) .. "+" .. dimensions["top"] - tonumber(originy) .. " "
                    assert(File.file_exists("working\\background.miff"))
                    os.execute("gm composite " .. geometry .. File_path .. " working\\background.miff " .. result_path)
                    if Config["pngout"] then
                        os.execute("pngout " .. result_path)
                    end
                    unit_scale = UnitScale
                    ScaleLib.do_scale(result_path, unit_scale, scale_directory)
                end
                --[[if Config["pngout"] then
                    os.execute(
                        "pngout" .. " " .. scale_directory .. pic:sub(1, -5) .. "_scaled.png" .. png_suffix_sprite
                    )
                end]]
            end
        end
    end

    local cmd = io.popen("cmd /C dir " .. OutputFolder .. " /B", "r")
    animlist = cmd:read("*a")
    cmd:close()
    for anim in animlist:gmatch("%d+_[%a%d_]+.aod") do
        local action_folder = OutputFolder .. "\\" .. anim .. "\\"
        if File.file_exists(action_folder .. "ALMT.txt") then
            if not File.dir_exists(OutputFolder .. "\\images\\") then
                File.make_dir(OutputFolder .. "\\images\\")
            end
            h = assert(io.open(action_folder .. "ALMT.txt", "rb"))
            local text = assert(h:read("*a"))
            assert(h:close())
            local steps = {}
            for sec_mark in text:gmatch("%d @(...)%:") do
                table.insert(steps, sec_mark)
            end
            if steps[1] ~= "N/A" then
                for step, sec_mark in ipairs(steps) do
                    local next_mark = steps[step + 1]
                    if next_mark then
                        steps[step] = tonumber(next_mark) - tonumber(sec_mark)
                    else
                        steps[step] = 1
                    end
                end
                local edited_folder = "scaled"
                local gifname = unit_name .. anim .. "_Sprite.gif"
                local ext = "_scaled.png "
                local cmd = io.popen("cmd /C dir " .. action_folder .. edited_folder .. "\\ /B", "r")
                steplist = cmd:read("*a")
                cmd:close()
                local _, count = string.gsub(steplist, ".png", "")
                --if #steps == count then print(anim) end
                --print(count)
                if File.dir_exists(action_folder .. edited_folder .. "\\") and #steps == count then
                    if force == "force" or not File.file_exists(action_folder .. gifname) then
                        local args = "magick -dispose previous -loop 0 "
                        for step, secs in ipairs(steps) do
                            if next(steps, step) ~= nil then
                                args =
                                    args .. "-delay " .. secs .. "x60" .. " " .. action_folder .. edited_folder .. "\\"
                                args = args .. "alod_SP00_" .. string.format("%02d", step - 1) .. ext
                            end
                        end
                        local outputdir
                        if Args["dump"] then
                            outputdir = Config["dump directory"]
                        else
                            outputdir = OutputFolder .. "\\images\\"
                        end
                        args = args .. outputdir .. gifname .. "  >nul 2>&1"
                        os.execute(args)
                        --print(args)
                        if Config["File Printouts"] then
                            print(unit_name .. " Sprite.gif generated")
                        end
                    end
                end
            end
        end
    end
end
return {
    GetGifs = GetGifs
}
