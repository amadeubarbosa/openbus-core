--
-- ftc.lua
--

local core = require "ftc.core"

local oil = require 'oil'
oil.orb = oil.init {flavor = "intercepted;corba;csockets;typed;cooperative;base"}
local orb = oil.orb

local coroutine = require "coroutine"
local error = error
local select = select
local unpack = unpack
local oo = require "loop.base"
module("ftc", oo.class)

if not oil.isrunning then
  oil.isrunning = true
  oil.tasks:register(coroutine.create(function() return orb:run() end))
end

local sockets = oil.kernel.base.Sockets

function __init(self, identifier, writable, size, host, port, accessKey)
  return core(sockets, identifier, writable, size, host, port, accessKey)
end

-- Invoke with concurrency
function invoke(self, func, ...)
  local res
  oil.main (function()
    res = {oil.pcall(func, unpack(arg))}
    oil.tasks:halt()
  end)
  if (not res[1]) then
    error(res[2])
  end
  return select(2, unpack(res))
end
