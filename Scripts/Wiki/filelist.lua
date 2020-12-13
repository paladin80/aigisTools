-- filelist.lua (Library)
-- v1.0
-- author: ShinyAfro
local config = require "lookup//config"
local file = require("lib/file")
local dl = require("lib/download")
local out = "out\\files"
local filelist_format_spacing = 0

local function get_filelist_changes(filelist_new)
  local base_url = 'http://assets.millennium-war.net/'
  h = io.open(out .. "\\files_old.txt", 'rb')
  if h then
    local filelist_old = assert(h:read('*a'))
    assert(h:close())
  
    local filelist_old_lines = {}  
	local filelist_urls = {}  
    local filelist_old_files = {}
    local filelist_new_lines = {}
    local filelist_new_files = {}
    local filelist_additions = 'Added:\n'
    local filelist_removals = '\n\nRemoved:\n'
    local filelist_changes = '\n\nChanged:\n'
  
    for A, B, C, D, E in filelist_new:gmatch('([%C]-),([^,]+),([^,]+),([^,]+),([%C]+)') do
	  if #E>filelist_format_spacing then filelist_format_spacing = #E end
	end
	
    for A, B, C, D, E in filelist_old:gmatch('([%C]-),([^,]+),([^,]+),([^,]+),([%C]+)') do
      local line = A..B..C..D..E
      local file = E
	  filelist_urls[file] = '<'..base_url..A..'/'..B..'>'
      filelist_old_lines[line] = true
      filelist_old_files[file] = true
    end
  
    for A, B, C, D, E in filelist_new:gmatch('([%C]-),([^,]+),([^,]+),([^,]+),([%C]+)') do
      local line = A..B..C..D..E
      local file = E
	  filelist_urls[file] = '<'..base_url..A..'/'..B..'>'
      if not filelist_old_lines[line] and filelist_old_files[file] then
	    filelist_changes = filelist_changes .. string.format('%-'..filelist_format_spacing..'s',file) .. ' '
	    if config['Change URLS'] then filelist_changes=filelist_changes..filelist_urls[file]..'\n'end
	  end
	  if not filelist_old_files[file] then
	    filelist_additions = filelist_additions .. string.format('%-'..filelist_format_spacing..'s',file) .. ' '
	    if config['Change URLS'] then filelist_additions=filelist_additions..filelist_urls[file]..'\n' end
	  end
      filelist_new_lines[line] = true
      filelist_new_files[file] = true
    end
  
    for file, line in pairs(filelist_old_files) do
  	  if not filelist_new_files[file] then filelist_removals = filelist_removals .. file .. '\n' end
    end
  
    local h =  assert(io.open("out\\changes.txt", 'wb'))
    assert(h:write(filelist_additions..filelist_removals..filelist_changes))
    assert(h:close())
  else
    print('Error: "files_old.txt" not found. "changes.txt" will not be generated. (changelist failed)')
  end
end

local function archive_filelist(filelist_new)
  if not file.dir_exists(out) then
    file.make_dir(out)
  end
  local h =  io.open(out .. "\\files.txt", 'rb')
  if h then
    local filelist_old = assert(h:read('*a'))
    assert(h:close())
    if filelist_new ~= filelist_old then
      h = assert(io.open(out .. "\\files_old.txt", 'wb'))
      assert(h:write(filelist_old))
      assert(h:close())
    end
  else
    print('Error: Pre-existing "Files.txt" not found. "files_old.txt" will not be generated. (archive failed)')
  end
end

local function get_filelist()
  if not file.dir_exists(out) then
    file.make_dir(out)
  end
  local list = _LookupCore.filelist()
  local files_text = dl.getlist_raw(list)
  return files_text
end

local function save_filelist(filelist)
  h = assert(io.open(out .. "\\files.txt", 'wb'))
    assert(h:write(filelist))
    assert(h:close())
end

return {
get_filelist = get_filelist,
archive_filelist = archive_filelist,
save_filelist = save_filelist,
get_filelist_changes = get_filelist_changes,
}