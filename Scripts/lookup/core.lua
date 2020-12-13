local function GRs733a4()
  h = io.open('Data\\XML\\GRs733a4', 'r')
  local data = h:read('*a')
  io.close(h)
  return data
end

local function QxZpjdfV()
  h = io.open('Data\\XML\\QxZpjdfV', 'r')
  local data = h:read('*a')
  io.close(h)
  return data
end

local function filelist()
  h = io.open('Data\\list\\URL.txt', 'r')
  local data = h:read('*a')
  io.close(h)
  return data
end

return{
  GRs733a4 = GRs733a4,
  QxZpjdfV = QxZpjdfV,
  filelist = filelist}