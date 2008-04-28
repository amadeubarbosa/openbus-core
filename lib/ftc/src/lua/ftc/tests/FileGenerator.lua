--
--  FileGenerator.lua
--
local print = print
local assert    = assert
local math      = math
local io        = io
local os        = os
local string    = string
local tostring  = tostring

local oo = require "loop.base"

module("ftc.tests.FileGenerator", oo.class)

local filePath
local size

function __init(self, filePath, size, content)
  local fp = assert(io.open(filePath, 'w'))
  if not content then
    for x=1, size do
      fp:write(string.char(math.random(255)))
    end
  else
    for x=1, size do
      fp:write(content)
    end
  end
  fp:close()
  return oo.rawnew( self, {
    filePath = filePath,
    size = size,
  } )
end

function chmod(self, mode)
  print(self.filePath)
  os.execute("chmod "..tostring(mode).." "..self.filePath)
end

function remove(self)
  os.execute("rm -f"..self.filePath)
end
