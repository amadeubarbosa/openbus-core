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

local log = require "openbus.util.logger"
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
local Access = require "openbus.core.services.Access"

local msg = require "openbus.core.services.messages"
local AccessControl = require "openbus.core.services.AccessControl"
local OfferRegistry = require "openbus.core.services.OfferRegistry"

return function(...)
	-- configuration parameters parser
	local Configs = ConfigArgs{
		busid = "OpenBus",
		host = "*",
		port = 2089,
	
		database = "openbus.db",
		certificate = "openbus.crt",
		privatekey = "openbus.key",
	
		leasetime = 180,
		expirationgap = 10,
	
		admin = {},
		validator = {},
	
		loglevel = 3,
		logfile = "",
		oilloglevel = 0,
		oillogfile = "",
		
		noauthorizations = false,
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
Usage:  ]],OPENBUS_PROGNAME,[[ [options]
Options:

  -busid <name>              identificador �nico do barramento
  -host <address>            endere�o de rede usado pelo barramento
  -port <number>             n�mero da porta usada pelo barramento

  -database <path>           arquivo de dados do barramento
  -certificate <path>        arquivo com certificado do barramento
  -privatekey <path>         arquivo com chave privada do barramento

  -leasetime <seconds>       tempo de lease dos logins de acesso
  -expirationgap <seconds>   tempo que os logins ficam v�lidas ap�s o lease

  -admin <user>              usu�rio com privil�gio de administra��o
  -validator <name>          nome de pacote de valida��o de login

  -loglevel <number>         n�vel de log gerado pelo barramento
  -logfile <path>            arquivo de log gerado pelo barramento
  -oilloglevel <number>      n�vel de log gerado pelo OiL (debug)
  -oillogfile <path>         arquivo de log gerado pelo OiL (debug)

  -noauthorizations          desativa o suporte a autoriza��es de oferta
  -nolegacy                  desativa o suporte � vers�o antiga do barramento

  -configs <path>            arquivo de configura��es adicionais do barramento
  
]])
			return 1 -- program's exit code
		end
	end

	-- create a set of admin users
	local adminUsers = {}
	for _, admin in ipairs(Configs.admin) do
		adminUsers[admin] = true
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
	setuplog(log, Configs.loglevel, Configs.logfile)
	setuplog(oillog, Configs.oilloglevel, Configs.oillogfile)

	-- setup bus access
	local orb = Access.createORB{ host=Configs.host, port=Configs.port }
	local access = Access{ orb=orb, legacy=not Configs.nolegacy }
	orb:setinterceptor(access, "corba")

	-- create SCS component
	local facets = {}
	copy(AccessControl, facets)
	copy(OfferRegistry, facets)
	newSCS{
		orb = orb,
		objkey = const.BusObjectKey,
		name = const.BusObjectKey,
		facets = facets,
		init = function()
			local params = {
				access = access,
				busid = Configs.busid,
				database = assert(opendb(Configs.database)),
				certificate = assert(readfilecontents(Configs.certificate)),
				privateKey = assert(readprivatekey(Configs.privatekey)),
				leaseTime = Configs.leasetime,
				expirationGap = Configs.expirationgap,
				admins = adminUsers,
				validators = validators,
				enforceAuth = not Configs.noauthorizations,
			}
			-- these object must be initialized in this order
			facets.CertificateRegistry:__init(params)
			facets.AccessControl:__init(params)
			facets.LoginRegistry:__init(params)
			facets.InterfaceRegistry:__init(params)
			facets.EntityRegistry:__init(params)
			facets.OfferRegistry:__init(params)
		end,
	}

	-- create legacy SCS components
	if access.legacy then
		local legacyIDL = require "openbus.core.legacy.idl"
		legacyIDL.loadto(orb)
	
		local AccessControlService = require "openbus.core.legacy.AccessControlService"
		local ACS = newSCS{
			orb = orb,
			objkey = "openbus_v1_05",
			name = "AccessControlService",
			facets = AccessControlService,
			receptacles = {RegistryServiceReceptacle="IDL:scs/core/IComponent:1.0"},
			init = function()
				local params = { access = access, admins = Configs.admin }
				-- these object must be initialized in this order
				AccessControlService.IAccessControlService:__init(params)
				AccessControlService.IManagement:__init(params)
			end,
		}
		local RegistryService = require "openbus.core.legacy.RegistryService"
		local RGS = newSCS{
			orb = orb,
			objkey = "IC",
			name = "RegistryService",
			facets = RegistryService,
			init = function()
				local params = { access = access }
				-- these object must be initialized in this order
				RegistryService.IManagement:__init(params)
			end,
		}
		ACS.IReceptacles:connect("RegistryServiceReceptacle", RGS.IComponent)
	end

	-- start ORB
	log:uptime(msg.BusSuccessfullyStarted)
	orb:run()
end
