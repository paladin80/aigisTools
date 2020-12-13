-- scale_image.lua
-- v1.2
-- originally written by: lzlis
-- main body moved to scale_calcs.lua by: illumini9
-- usage: lua.exe scale_image.lua [input_file(png)] [scale]
-- [[note: this uses "working" folder and will put the output there called "scaled.png"]]
-- note by illumini9: changed to output in the same folder the orignal image came from
-- note: scale should be given as a decimal e.g. 1.5
--
-- changes:
-- v1.2 updated to use gm.lua library
-- v1.1 doing bilinear filtering by hand

local scale_lib = require("lib/scale_calcs")

local image, scale, out = ...
scale = assert(tonumber(scale))

scale_lib.do_scale(image, scale, out)