-- $Id$

local _G = require "_G"
local assert = _G.assert
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

local logger = require "openbus.util.logger"
local database = require "openbus.util.database"
local opendb = database.open
local server = require "openbus.util.server"
local ConfigArgs = server.ConfigArgs
local newSCS = server.newSCS
local setuplog = server.setuplog
local readfilecontents = server.readfilecontents
local readprivatekey = server.readprivatekey

local idl = require "openbus.core.idl"
local const = idl.const
local Access = require "openbus.core.Access"

local msg = require "openbus.core.services.messages"
local AccessControl = require "openbus.core.services.AccessControl"
local OfferRegistry = require "openbus.core.services.OfferRegistry"

return function(...)
	-- configuration parameters parser
	local Configs = ConfigArgs{
		host = "*",
		port = 2089,
	
		database = "openbus.db",
		certificate = "openbus.crt",
		privatekey = "openbus.key",
	
		leasetime = 180,
		expirationgap = 10,
	
		admin = {},
		validator = {},
	
		loginloglevel = 3,
		loginlogfile = "",
		offerloglevel = 3,
		offerlogfile = "",
		oilloglevel = 0,
		oillogfile = "",
		
		nolegacy = false,
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

  -host <address>            endereço de rede usado pelo barramento
  -port <number>             número da porta usada pelo barramento

  -database <path>           arquivo de dados do barramento
  -ceritficate <path>        arquivo com certificado do barramento
  -privatekey <path>         arquivo com chave privada do barramento

  -leasetime <seconds>       tempo de lease dos logins de acesso
  -expirationgap <seconds>   tempo que os logins ficam válidas após o lease

  -admin <user>              usuário com privilégio de administração
  -validator <name>          nome de pacote de validação de login

  -loginloglevel <number>   nível de log gerado pelos serviços de acesso
  -loginlogfile <path>      arquivo de log gerado pelos serviços de acesso
  -offerloglevel <number>    nível de log gerado pelos serviços de oferta
  -offerlogfile <path>       arquivo de log gerado pelos serviços de oferta
  -oilloglevel <number>      nível de log gerado pelo OiL (debug)
  -oillogfile <path>         arquivo de log gerado pelo OiL (debug)

  -nolegacy                  desativa o suporte à versão antiga do barramento

  -configs <path>            arquivo de configurações adicionais do barramento
  
]])
			return 1 -- program's exit code
		end
	end

	-- load all password validators to be used
	local validators = {}
	for index, package in ipairs(Configs.validator) do
		validators[#validators+1] = {
			name = package,
			validate = assert(require(package)(Configs)),
		}
	end
	assert(#validators>0, msg.NoPasswordValidators)

	-- setup log files
	local loginlog = logger()
	local offerlog = logger()
	setuplog(loginlog, Configs.loginloglevel, Configs.loginlogfile)
	setuplog(offerlog, Configs.offerloglevel, Configs.offerlogfile)
	setuplog(oillog, Configs.oilloglevel, Configs.oillogfile)

	-- setup bus access
	local orb = Access.initORB{ host=Configs.host, port=Configs.port }
	local access = Access{
		orb = orb,
		log = loginlog,
		legacy = not Configs.nolegacy,
	}

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
			
			leaseTime = Configs.leasetime,
			expirationGap = Configs.expirationgap,
			
			database = assert(opendb(Configs.database)),
			certificate = assert(readfilecontents(Configs.certificate)),
			privateKey = assert(readprivatekey(Configs.privatekey)),
			
			admins = Configs.admin,
			validators = validators,
			
			loginlog = loginlog,
			offerlog = offerlog,
		},
	}

	-- create legacy SCS components
	if access.legacy then
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
	loginlog:uptime(msg.BusSuccessfullyStarted)
	orb:run()
end
