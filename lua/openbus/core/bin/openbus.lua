-- $Id$

local _G = require "_G"
local ipairs = _G.ipairs
local require = _G.require
local select = _G.select

local io = require "io"
local stderr = io.stderr

local os = require "os"
local getenv = os.getenv

local table = require "loop.table"
local copy = table.copy

local oil = require "oil"
local oillog = require "oil.verbose"

local log = require "openbus.core.util.logger"
local msg = require "openbus.core.util.messages"
local database = require "openbus.core.util.database"
local opendb = database.open
local server = require "openbus.core.util.server"
local ConfigArgs = server.ConfigArgs
local newSCS = server.newSCS
local setuplog = server.setuplog
local readprivatekey = server.readprivatekey

local idl = require "openbus.core.idl"
local assert = idl.serviceAssertion
local const = idl.values.services
local Access = require "openbus.core.Access"
local AccessControl = require "openbus.core.services.AccessControl"
local OfferRegistry = require "openbus.core.services.OfferRegistry"

return function(...)
	-- configuration parameters parser
	local Configs = ConfigArgs{
		host = "*",
		port = 2089,
	
		admin = {},
		validator = {},
	
		database = "openbus.db",
		privatekey = "openbus.key",
	
		leasetime = 180,
		expirationgap = 10,
	
		loglevel = 3,
		logfile = "",
		oilloglevel = 0,
		oillogfile = "",
	}

	-- parse configuration file
	Configs:configs("configs", getenv("OPENBUS_CONFIG") or "openbus.cfg")

	-- parse command line parameters
	do
		io.write(msg.CopyrightNotice, "\n")
		local argidx, errmsg = Configs(...)
		if not argidx or argidx <= select("#", ...) then
			if errmsg ~= nil then
				stderr:write(errmsg,"\n")
			end
			stderr:write([[
Usage:  ]],OPENBUS_PRONAME,[[ [options]
Options:

  -host <address>            endereço de rede usado pelo serviço
  -port <number>             número da porta usada pelo serviço

  -admin <user>              usuário com privilégio de administração
  -validator <name>          nome de pacote de validação de login

  -database <path>           arquivo de dados do serviço
  -privatekey <path>         arquivo com chave privada do serviço

  -leasetime <seconds>       tempo de lease das credenciais emitidas
  -expirationgap <seconds>   tempo que credenciais ficam válidas após o lease

  -logmail <email>           e-mail usado para notificação pelo serviço
  -loglevel <number>         nível de log gerado pelo serviço
  -logfile <path>            arquivo de log gerado pelo serviço
  -oilloglevel <number>      nível de log gerado pelo OiL (debug)
  -oillogfile <path>         arquivo de log gerado pelo OiL (debug)

  -configs <path>            arquivo com configurações adicionais do serviço
  
]])
			return 1 -- program's exit code
		end
	end

	-- setup log files
	setuplog(log, Configs.loglevel, Configs.logfile)
	setuplog(oillog, Configs.oilloglevel, Configs.oillogfile)

	-- load all password validators to be used
	local validators = {}
	for index, package in ipairs(Configs.validator) do
		validators[#validators+1] = {
			name = package,
			validate = assert(require(package)(Configs)),
		}
	end

	-- setup bus access
	local access = Access()
	local orb = access.orb

	-- create SCS component
	local facets = {}
	copy(AccessControl, facets)
	copy(OfferRegistry, facets)
	newSCS{
		orb = orb,
		objkey = const.BusObjectKey,
		name = const.BusObjectKey,
		facets = facets,
		params = {
			access = access,
			database = assert(opendb(Configs.database)),
			leaseTime = Configs.leasetime,
			privateKey = assert(readprivatekey(Configs.privatekey)),
			validators = validators,
			admins = Configs.admin,
		},
	}

	-- create legacy SCS components
	do
		local legacyIDL = require "openbus.core.legacy.idl"
		legacyIDL.loadto(orb)
	
		local ACS = newSCS{
			orb = orb,
			objkey = "openbus_v1_50",
			name = "AccessControlService",
			facets = require "openbus.core.legacy.AccessControlService",
			receptacles = {RegistryServiceReceptacle="IDL:scs/core/IComponent:1.0"},
			params = { access = access, admins = Configs.admin },
		}
		local RGS = newSCS{
			orb = orb,
			objkey = "IC",
			name = "RegistryService",
			facets = require "openbus.core.legacy.RegistryService",
			params = { access = access },
		}
		ACS.IReceptacles:connect("RegistryServiceReceptacle", RGS.IComponent)
	end

	-- start ORB
	log:uptime(msg.BusSuccessfullyStarted)
	orb:run()
end
