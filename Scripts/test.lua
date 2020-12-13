local data = ''
local loc_localisation = 'Data\\localisation\\'
h = io.open(loc_localisation..'Name.txt', 'r+')
local text = h:read('*a')
for key, value in text:gmatch('([^=]+)=([^%c]+)') do data = data..value:match("^%s*(.-)%s*$")..'\n' end
h:write(data)
io.close(h)