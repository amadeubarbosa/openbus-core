local _G = require "_G"
local getmetatable = _G.getmetatable
local setmetatable = _G.setmetatable
local rawget = _G.rawget
local rawset = _G.rawset

local array = require "table"
local unpack = array.unpack or _G.unpack

local hash = require "lce.hash"
local sha256 = hash.sha256

local table = require "loop.table"
local memoize = table.memoize

local LRUCache = require "loop.collection.LRUCache"

local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local log = require "openbus.util.logger"
local oo = require "openbus.util.oo"
local class = oo.class

local idl = require "openbus.core.idl"
local const = idl.const.services.access_control
local types = idl.types.services
local msg = require "openbus.core.messages"
local access = require "openbus.core.Access"
local setNoPermSysEx = access.setNoPermSysEx
local Context = access.Context
local Interceptor = access.Interceptor
local receiveBusRequest = Interceptor.receiverequest



local function alwaysIndex(default)
  return setmetatable({}, { __index = function() return default end })
end

local Anybody = alwaysIndex(true)
local Everybody = alwaysIndex(true)
local PredefinedUserSets = {
  none = alwaysIndex(nil),
  any = Anybody,
  all = Everybody,
}

local function getLoginInfoFor(self, loginId)
  return self.LoginRegistry:getLoginEntry(loginId)
      or {id=loginId,entity="<unknown>"}
end



local BusInterceptor = class({}, Context, Interceptor)

function BusInterceptor:__init()
  self.context = self
  self.signedChainOf = memoize(function(chain) -- [chain] = SignedChainCache
    return LRUCache{ -- [target] = signedChain
      retrieve = function(target)
        local originators = { unpack(chain.originators) }
        originators[#originators+1] = chain.caller
        return self.AccessControl:encodeChain({
          originators = originators,
          caller = self.login,
        }, target)
      end,
    }
  end, "k")
  do
    local forAllOps = Everybody
    
    function self.newOpAccess(access)
      local default
      return setmetatable(access or {}, {
        __index = function() return default or forAllOps end,
        __newindex = function(self, k, v)
          if k == "*" then
            default = v
          else
            rawset(self, k, v)
          end
        end,
      })
    end
    
    local defOpAccess = setmetatable({}, {
      __index = function() return forAllOps end,
      __newindex = function(self, k, v)
        if k == "*" and v then
          forAllOps = v
        else
          rawset(self, k, v)
        end
      end,
    })
    
    self.grantedUsers = setmetatable({
      ["*"] = defOpAccess, -- to get the default
      ["IDL:scs/core/IComponent:1.0"] = self.newOpAccess{
        getFacet = Anybody,
        getFacetByName = Anybody,
      },
    }, { __index = function() return defOpAccess end })
  end
end

function BusInterceptor:unmarshalCredential(...)
  local credential = Interceptor.unmarshalCredential(self, ...)
  if credential ~= nil then
    local chain = credential.chain
    if chain == nil then -- unjoined non-legacy call
      chain = {
        signature = false,
        originators = {},
        caller = getLoginInfoFor(self, credential.login),
        target = self.login.entity,
      }
      credential.chain = chain
    elseif chain.signature ~= nil then -- joined non-legacy call
      local originators = chain.originators
      originators[#originators+1] = chain.caller -- add last originator
      local caller = getLoginInfoFor(self, credential.login)
      chain.caller = caller
      local target = chain.target
      if target ~= caller.entity then
        chain.caller = {id="<unknown>",entity=target} -- raises "InvalidChain"
      end
      chain.target = self.login.entity
    end
  end
  return credential
end

function BusInterceptor:signChainFor(target, chain)
  return self.signedChainOf[chain]:get(target)
end

function BusInterceptor:receiverequest(request)
  if request.servant ~= nil then -- servant object does exist
    local op = request.operation_name
    if op:find("_", 1, true) ~= 1
    or op:find("_[gs]et_", 1) == 1 then -- not CORBA obj op
      receiveBusRequest(self, request)
      if request.success == nil then
        local granted = self.grantedUsers[request.interface.repID][op]
        local chain = self:getCallerChain()
        if chain ~= nil then
          local login = chain.caller
          if not granted[login.entity] then
            if chain.signature == nil then -- legacy call (OpenBus 1.5)
              setNoPermSysEx(request, 0)
              log:exception(msg.DeniedLegacyBusCall:tag{
                operation = request.operation.name,
                remote = login.id,
                entity = login.entity,
              })
            else
              request.success = false
              request.results = {{_repid = types.UnauthorizedOperation}}
              log:exception(msg.DeniedBusCall:tag{
                operation = request.operation.name,
                remote = login.id,
                entity = login.entity,
              })
            end
          end
        elseif granted ~= Anybody then
          setNoPermSysEx(request, const.NoCredentialCode)
          log:exception(msg.DeniedOrdinaryCall:tag{
            operation = request.operation.name,
          })
        end
      end
    end
  end
end

function BusInterceptor:setGrantedUsers(interface, operation, users)
  local accessByIface = self.grantedUsers
  local accessByOp = rawget(accessByIface, interface)
  if accessByOp == nil then
    accessByOp = self.newOpAccess()
    accessByIface[interface] = accessByOp
  end
  accessByOp[operation] = PredefinedUserSets[users] or users
end



return {
  initORB = access.initORB,
  Interceptor = BusInterceptor,
}
