local _G = require "_G"
local getmetatable = _G.getmetatable
local newproxy = _G.newproxy
local setmetatable = _G.setmetatable
local rawget = _G.rawget
local rawset = _G.rawset

local cothread = require "cothread"
local running = cothread.running

local hash = require "lce.hash"
local sha256 = hash.sha256

local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local log = require "openbus.util.logger"
local oo = require "openbus.util.oo"
local class = oo.class

local idl = require "openbus.core.idl"
local const = idl.const.services.access_control
local msg = require "openbus.core.messages"

local access = require "openbus.core.Access"
local Interceptor = access.Interceptor
local receiveBusRequest = Interceptor.receiverequest



local BusInterceptor = class({}, Interceptor)

function BusInterceptor:validateChain(chain, caller)
  if chain == nil then
    chain = { callers = {caller} }
  else
    if chain.signature ~= nil then -- is not a legacy chain (OpenBus 1.5)
                                   -- legacy chain is always created correctly
      local signed = self.buskey:verify(sha256(chain.encoded), chain.signature)
      if signed and chain.target == caller.id then
        local callers = chain.callers
        callers[#callers+1] = caller -- add caller to the chain
      else
        chain = nil -- invalid chain: unsigned or chain was not for the caller
      end
    end
  end
  return chain
end

function BusInterceptor:joinedChainFor(remoteid, chain)
  local callers = { unpack(chain.callers) }
  callers[#callers+1] = self.login
  return self.AccessControl:encodeChain(remoteid, callers)
end



return {
  initORB = access.initORB,
  Interceptor = BusInterceptor,
}
