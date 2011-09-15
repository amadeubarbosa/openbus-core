local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs

local array = require "table"
local unpack = array.unpack or _G.unpack

local debug = require "debug"
local traceback = debug.traceback

local log = require "openbus.core.util.logger"
local msg = require "openbus.core.util.messages"
local makeaux = require "openbus.core.idl.makeaux"
local parsed = require "openbus.core.idl.parsed"



local types, values, throw = {}, {}, {}
for _, parsed in ipairs(parsed) do
	if parsed.name == "tecgraf" then
		makeaux(parsed, types, values, throw)
	end
end

local idl = {
	types = types.tecgraf.openbus.core.v2_00,
	values = values.tecgraf.openbus.core.v2_00,
	throw = throw.tecgraf.openbus.core.v2_00,
}

do
	local const = idl.values
	const.Version = "2_00"
	const.BusObjectKey = "OpenBus"
	local const = idl.values.services.access_control
	const.CertificateRegistryFacet = "CertificateRegistry_2_00"
	const.AccessControlFacet = "AccessControl_2_00"
	const.LoginRegistryFacet = "LoginRegistry_2_00"
	local const = idl.values.services.offer_registry
	const.OfferRegistryFacet = "OfferRegistry_2_00"
	const.EntityRegistryFacet = "EntityRegistry_2_00"
end


local ServiceFailureRepId = idl.types.services.ServiceFailure
function idl.throw.ServiceFailure(fields)
	log:failure(traceback(msg.ServiceFailure:tag(fields)))
	fields[1] = ServiceFailureRepId
	error(fields)
end

local ServiceFailure = idl.throw.ServiceFailure
function idl.serviceAssertion(ok, errmsg, ...)
	if not ok then ServiceFailure{message = errmsg or "assertion failed"} end
	return ok, errmsg, ...
end

function idl.loadto(orb)
	orb.TypeRepository.registry:register(unpack(parsed))
end

return idl
