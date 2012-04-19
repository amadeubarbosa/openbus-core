local _G = require "_G"
local getmetatable = _G.getmetatable
local newproxy = _G.newproxy
local setmetatable = _G.setmetatable
local rawget = _G.rawget
local rawset = _G.rawset

local hash = require "lce.hash"
local sha256 = hash.sha256

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
local Interceptor = access.Interceptor
local receiveBusRequest = Interceptor.receiverequest



local function alwaysIndex(default)
  local index = newproxy(true)
  getmetatable(index).__index = function() return default end
  return index
end

local Anybody = alwaysIndex(true)
local Everybody = newproxy(Anybody) -- copy of Anybody
local PredefinedUserSets = {
  none = alwaysIndex(nil),
  any = Anybody,
  all = Everybody,
}



local BusInterceptor = class({}, Interceptor)

function BusInterceptor:__init()
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



function BusInterceptor:setGrantedUsers(interface, operation, users)
  local accessByIface = self.grantedUsers
  local accessByOp = rawget(accessByIface, interface)
  if accessByOp == nil then
    accessByOp = self.newOpAccess()
    accessByIface[interface] = accessByOp
  end
  accessByOp[operation] = PredefinedUserSets[users] or users
end



local UnauthorizedOperationException = { _repid = types.UnauthorizedOperation }
function BusInterceptor:receiverequest(request)
  if request.servant ~= nil then -- servant object does exist
    local opName = request.operation_name
    if opName:find("_", 1, true) ~= 1
    or opName:find("_[gs]et_", 1) == 1 then -- not CORBA obj op
      receiveBusRequest(self, request)
      if request.success == nil then
        local granted = self.grantedUsers[request.interface.repID][opName]
        local chain = self:getCallerChain()
        if chain ~= nil then
          local callers = chain.callers
          local login = callers[#callers]
          if not granted[login.entity] then
            request.success = false
            request.results = {UnauthorizedOperationException}
            log:access(msg.DeniedBusCall:tag{
              operation = request.operation.name,
              login = login.id,
              entity = login.entity,
            })
          else
            log:access(msg.GrantedBusCall:tag{
              operation = request.operation.name,
              login = login.id,
              entity = login.entity,
            })
          end
        elseif granted ~= Anybody then
          request.success = false
          request.results = {self.orb:newexcept{
            _repid = sysex.NO_PERMISSION,
            completed = "COMPLETED_NO",
            minor = const.InvalidLoginCode,
          }}
          log:access(msg.DeniedCallWithoutCredential:tag{
            operation = request.operation.name,
          })
        else
          log:access(msg.GrantedCallWithoutCredential:tag{
            operation = request.operation.name,
          })
        end
      end
    end
  end
end



return {
  initORB = access.initORB,
  Interceptor = BusInterceptor,
}
