local _G = require "_G"
local getmetatable = _G.getmetatable
local newproxy = _G.newproxy
local setmetatable = _G.setmetatable
local rawget = _G.rawget
local rawset = _G.rawset

local cothread = require "cothread"
local running = cothread.running

local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local log = require "openbus.util.logger"
local oo = require "openbus.util.oo"
local class = oo.class

local idl = require "openbus.core.idl"
local const = idl.const.services.access_control
local msg = require "openbus.core.messages"

local Access = require "openbus.core.Access"
local receiveBusRequest = Access.receiverequest



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



local CoreServiceAccess = class({}, Access)

function CoreServiceAccess:__init()
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

function CoreServiceAccess:setGrantedUsers(interface, operation, users)
	local accessByIface = self.grantedUsers
	local accessByOp = rawget(accessByIface, interface)
	if accessByOp == nil then
		accessByOp = self.newOpAccess()
		accessByIface[interface] = accessByOp
	end
	accessByOp[operation] = PredefinedUserSets[users] or users
end

function CoreServiceAccess:receiverequest(request)
	if request.servant ~= nil then -- servant object does exist
		local opName = request.operation_name
		if opName:find("_", 1, true) ~= 1 then -- not CORBA obj op
			receiveBusRequest(self, request)
			local granted = self.grantedUsers[request.interface.repID][opName]
			local callers = self:getCallerChain()
			if callers ~= nil then
				local login = callers[#callers]
				if not granted[login.entity] and not granted[callers[1].entity] then
					request.success = false
					request.results = {self.orb:newexcept{
						_repid = sysex.NO_PERMISSION,
						completed = "COMPLETED_NO",
						minor = const.DeniedLoginCode,
					}}
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

return CoreServiceAccess
