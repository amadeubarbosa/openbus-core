local _G = require "_G"
local error = _G.error
local getenv = _G.getenv
local ipairs = _G.ipairs
local loadfile = _G.loadfile
local next = _G.next
local pairs = _G.pairs
local setmetatable = _G.setmetatable
local tostring = _G.tostring
local type = _G.type

local array = require "table"
local concat = array.concat

local io = require "io"
local openfile = io.open

local lce = require "lce"
local readprivatekey = lce.key.readprivatefrompemfile
local readcertificate = lce.x509.readfromderfile

local Arguments = require "loop.compiler.Arguments"

local ComponentContext = require "scs.core.ComponentContext"

local oo = require "openbus.util.oo"
local class = oo.class

local log = require "openbus.core.util.logger"
local msg = require "openbus.core.util.messages"
local idl = require "openbus.core.idl"
local assert = idl.serviceAssertion



local module = {}



local SafeEnv = {__index = { error = error, getenv = getenv }}

local function defaultAdd(list, value)
	list[#list+1] = tostring(value)
end

function module.setuplog(logger, level, path, mode)
	logger:level(level)
	if path ~= nil and path ~= "" then
		local file, errmsg = openfile(path, mode or "a")
		if file == nil then
			log:warn(msg.BadLogFile:tag{path=path,errmsg=errmsg})
		else
			logger.viewer.output = file
		end
	end
end

function module.readpublickey(path)
	local result, errmsg = readcertificate(path)
	if result then
		result, errmsg = result:getpublickey()
		if result then
			return result
		end
	end
	return nil, msg.UnableToReadPublicKey:tag{ path = path, errmsg = errmsg }
end

function module.readprivatekey(path)
	local result, errmsg = readprivatekey(path)
	if result then
		return result
	end
	return nil, msg.UnableToReadPrivateKey:tag{ path = path, errmsg = errmsg }
end

function module.newSCS(params)
	-- cria um componente SCS
	local component = ComponentContext(params.orb, { -- component id
		name = params.name or "unamed SCS component",
		major_version = params.major_version or 1,
		minor_version = params.minor_version or 0,
		patch_version = params.patch_version or 0,
		platform_spec = params.platform_spec or "",
	}, { -- keys
		IComponent = params.objkey,
	})

	-- adiciona as facetas e receptáculos do componente
	local facets = params.facets
	for name, obj in pairs(facets) do
		component:addFacet(obj.__objkey, obj.__type, obj, obj.__objkey)
	end
	local receptacles = params.receptacles
	if receptacles ~= nil then
		for name, iface in pairs(receptacles) do
			local conn
			if type(iface) ~= "string" then
				iface, conn = iface.__type, iface
			end
			component:addReceptacle(name, iface)
			if conn ~= nil then
				local receptacles = component.IComponent:getFacetByName("IReceptacles")
				receptacles:connect(name, conn)
			end
		end
	end
	
	function component:getConnected(name)
		local receptDesc = self._receptacles[name]
		if receptDesc ~= nil then
			local _, connDesc = next(receptDesc.connections)
			if connDesc then
				return connDesc.objref
			end
		end
	end
	
	-- inicia o componente
	local data = params.params
	function component.IComponent:startup()
		for name, obj in pairs(facets) do
			if obj.startup ~= nil then
				obj:startup(data)
			end
		end
	end
	local trap = params.trap
	function component.IComponent:shutdown()
		for name, obj in pairs(facets) do
			if obj.shutdown ~= nil then
				obj:shutdown()
			end
		end
		if trap ~= nil then trap() end
		local errors = self.context:deactivateComponent()
		for name, error in pairs(errors) do
			errors[#errors+1] = tostring(error)
		end
		assert(errors == 0, concat(errors, "\n"))
	end
	component.IComponent:startup()
	
	return component
end



module.ConfigArgs = class({
	__call = Arguments.__call, -- no metamethod inheritance
	-- mensagens de erro nos argumentos de linha de comando
	_badnumber = "valor do parâmetro '%s' é inválido (número esperado ao invés de '%s')",
	_missing = "nenhum valor definido para o parâmetro '%s'",
	_unknown = "parâmetro inválido '%s'",
	_norepeat = "parâmetro '%s' só pode ser definido uma vez",
}, Arguments)

function module.ConfigArgs:configs(_, path)
	local sandbox = setmetatable({}, SafeEnv)
	local loader, errmsg = loadfile(path, "t", sandbox)
	if loader ~= nil then
		loader() -- let errors in config file propagate
		for name, value in pairs(sandbox) do
			local kind = type(self[name])
			if kind == "nil" then
				log:misconfig(msg.BadParamInConfigFile:tag{
					configname = name,
					path = path,
				})
				self[name] = value
			elseif kind ~= type(value) then
				log:misconfig(msg.BadParamTypeInConfigFile:tag{
					configname = name,
					path = path,
					expected = kind,
					actual = type(value),
				})
			elseif kind == "table" then
				local list = self[name]
				local add = list.add or defaultAdd
				for index, value in ipairs(value) do
					local errmsg = add(list, tostring(value))
					if errmsg ~= nil then
						log:misconfig(msg.BadParamListInConfigFile:tag{
							configname = name,
							index = index,
							path = path,
						})
					end
				end
			else
				self[name] = value
			end
		end
	else
		log:misconfig(msg.ConfigFileNotFound:tag{path=path})
	end
end



return module