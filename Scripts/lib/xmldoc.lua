-- xmldoc.lua library
-- v1.0
-- author: lzlis
_LookupCore = require("lookup/core")
local decode = require("lib/decode")
local decompress = require("lib/decompress")

local xml_map = {
  ["cards"] = _LookupCore.GRs733a4(),
  ["GRs733a4"] = _LookupCore.GRs733a4(),
  ["missions"] = _LookupCore.QxZpjdfV(),
  ["QxZpjdfV"] = _LookupCore.QxZpjdfV(),
}

local function getfile(id, fname)
  text = xml_map[fname]
  text = decode.decode_xml(text)
  text = decompress.decompress(text)
  return text
end

local function getfileraw(id, fname)
  text = xml_map[fname]
  text = decode.decode_xml(text)
  --text = decompress.decompress(text)
  return text
end

return {
  getfile = getfile,
  getfileraw = getfileraw,
}
