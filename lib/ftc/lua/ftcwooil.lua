--
-- ftcwooil.lua
--

local sockets = require "socket.core"
local core = require "ftc.core"

local oo = require "loop.base"
module("ftc", oo.class)

function __init(self, identifier, writable, size, host, port, accessKey)
  return core(sockets, identifier, writable, size, host, port, accessKey)
end
