return function(...)
  local _G = require "_G"
  local print = _G.print
  local select = _G.select

  local array = require "table"
  local concat = array.concat
  local insert = array.insert

  local string = require "string"
  local format = string.format

  local io = require "io"
  local openfile = io.open
  local stderr = io.stderr

  local os = require "os"
  local getenv = os.getenv

  local table = require "loop.table"
  local copy = table.copy

  local oillog = require "oil.verbose"

  local openbus = require "openbus"
  local initorb = openbus.initORB

  local console = require "openbus.console.utils"
  local processargs = console.processargs

  local log = require "openbus.util.logger"
  local server = require "openbus.util.server"
  local ConfigArgs = server.ConfigArgs
  local setuplog = server.setuplog
  --local sandbox = require "openbus.util.sandbox"
  --local newsandbox = sandbox.create

  local msg = require "openbus.core.admin.messages"
  local Description = require "openbus.core.admin.Description"
  local script = require "openbus.core.admin.script"
  local setorb = script.setorb

  local SSLRequiredOptions = {
    required = true,
    supported = true,
  }

  local function getoptcfg(configs, field, default)
    local value = configs[field]
    if value ~= default then
      return value
    end
  end

  -- TODO: assure it uses the same error code table as 'busservices'
  local errcode = {
    IllegalConfigurationParameter = 1,
    MissingSecureConnectionAuthenticationKey = 20,
    MissingSecureConnectionAuthenticationCertificate = 21,
    InvalidSecurityLayerMode = 23,
  }

  -- configuration parameters parser
  local executables = {}
  local Configs = ConfigArgs{
    busref = "",
    entity = "admin",
    privatekey = "",
    password = "",
    domain = "",
  
    sslmode = "",
    sslcafile = "",
    sslcapath = "",
    sslcert = "",
    sslkey = "",
    
    loglevel = 1,
    logfile = "",
    oilloglevel = 0,
    oillogfile = "",

    interactive = false,
    version = false,
    noenvironment = false,

    help = false,
  }
  function Configs:execute(_, value)
    executables[#executables+1] = {kind="code", value=value}
  end
  function Configs:load(_, value)
    executables[#executables+1] = {kind="module", value=value}
  end
  Configs._alias = {
    i = "interactive",
    v = "version",
    e = "execute",
    l = "load",
    E = "noenvironment",
    h = "help",
  }

  do -- parse configuration file
    local path = getenv("OPENBUS_ADMINCFG")
    if path == nil then
      path = "busadmin.cfg"
      local file = openfile(path)
      if file == nil then goto done end
      file:close()
    end
    Configs:configs("configs", path)
    ::done::
  end

  -- parse command line parameters
  local argidx, errmsg = Configs(...)
  if argidx == nil then
    stderr:write(errmsg,"\n")
    Configs.help = true
  end
  if Configs.help then
    stderr:write([[
Usage:  ]],OPENBUS_PROGNAME,[[ [options] <script file> <script args>
Options:

  -busref <path|host:port>   arquivo de IOR ou endereço do barramento
  -entity <name>             entidade de autenticação
  -privatekey <path>         arquivo com chave de autenticação da entidade
  -password <text>           senha de autenticação da entidade
  -domain <name>             domínio da senha de autenticação

  -sslmode <mode>            ativa o suporte SSL através das opções 'supported' ou 'required'
  -sslcapath <path>          diretório com certificados de CAs a serem usados na autenticação SSL
  -sslcafile <path>          arquivo com certificados de CAs a serem usados na autenticação SSL
  -sslcert <path>            arquivo com certificado do barramento
  -sslkey <path>             arquivo com chave privada do barramento

  -loglevel <number>         nível de log gerado pelo barramento
  -logfile <path>            arquivo de log gerado pelo barramento
  -oilloglevel <number>      nível de log gerado pelo OiL (debug)
  -oillogfile <path>         arquivo de log gerado pelo OiL (debug)

  -i, -interactive           ativa modo interativo
  -e, -execute <code>        executa o código Lua
  -l, -load <module>         carrega o módulo Lua
  -v, -version               exibe a versão do probrama

  -configs <path>            arquivo de configurações adicionais

  -h, -help                  exibe essa mensagem e encerra a execução
]])
    return errcode.IllegalConfigurationParameter
  end

  if #executables == 0 and argidx > select("#", ...) then
    Configs.interactive = true
    Configs.version = true
  end

  if Configs.version then
    local idl = require "openbus.core.idl"
    local version = concat({
      idl.const.MajorVersion,
      idl.const.MinorVersion,
      0,
      OPENBUS_CODEREV,
    }, ".")
    print("OpenBus Admin Console "..version..
          "  Copyright (C) 2006-2017 Tecgraf, PUC-Rio")
  end

  -- setup log files
  local logfile = setuplog(log, Configs.loglevel, Configs.logfile)
  if logfile ~= nil then OPENBUS_SETLOGPATH(logfile) end
  log:config(msg.CoreServicesLogLevel:tag{value=Configs.loglevel})
  setuplog(oillog, Configs.oilloglevel, Configs.oillogfile)
  log:config(msg.OilLogLevel:tag{value=Configs.oilloglevel})

  -- setup bus access
  local sslcfg = {
    key = getoptcfg(Configs, "sslkey", ""),
    certificate = getoptcfg(Configs, "sslcert", ""),
    cafile = getoptcfg(Configs, "sslcafile", ""),
    capath = getoptcfg(Configs, "sslcapath", ""),
  }
  local sslmode, orbflv, orbopt = Configs.sslmode
  if SSLRequiredOptions[sslmode] ~= nil then
    orbflv = "cooperative;corba;corba.intercepted;corba.ssl;kernel.ssl"
    orbopt = {
      security = Configs.sslmode == "required" and "required" or nil,
      ssl = sslcfg,
    }
    if sslcfg.key ~= nil or sslcfg.certificate ~= nil then
      if sslcfg.key == nil then
        log:misconfig(msg.MissingSecureConnectionAuthenticationKey)
        return errcode.MissingSecureConnectionAuthenticationKey
      end
      if sslcfg.certificate == nil then
        log:misconfig(msg.MissingSecureConnectionAuthenticationCertificate)
        return errcode.MissingSecureConnectionAuthenticationCertificate
      end
      log:config(msg.SecureConnectionAuthenticationKey:tag{
        path = sslcfg.key,
      })
      log:config(msg.SecureConnectionAuthenticationCertificate:tag{
        path = sslcfg.certificate,
      })
    end
    if sslcfg.cafile ~= nil then
      log:config(msg.SecureConnectionCertificationAuthorityListFile:tag{path=sslcfg.cafile})
    elseif sslcfg.capath ~= nil then
      log:config(msg.SecureConnectionCertificationAuthorityDirectory:tag{path=sslcfg.capath})
    end
  elseif sslmode ~= "" then
    log:misconfig(msg.InvalidSecurityLayerMode:tag{
      value = Configs.sslmode,
    })
    return errcode.InvalidSecurityLayerMode
  end
  local orb = initorb{
    flavor = orbflv,
    options = orbopt,
  }
  if orbopt ~= nil then
    log:config(sslmode == "required" and msg.SecureConnectionEnforced
                                      or msg.SecureConnectionEnabled)
    log:config(msg.SecureConnectionPortNumber:tag{port=orb.sslport})
  end
  log:config(msg.ServicesListeningAddress:tag{host=orb.host,port=orb.port})

  setorb(orb)
  copy(script, _G)
  _G.setorb = nil
  function _G.newdesc()
    return Description()
  end

  if Configs.busref ~= "" then
    local value
    if Configs.privatekey ~= "" then
      value = format("login(%q, %q, %q)", Configs.busref,
                                          Configs.entity,
                                          Configs.privatekey)
    elseif Configs.password ~= "" then
      value = format("login(%q, %q, %q, %q)", Configs.busref,
                                              Configs.entity,
                                              Configs.password,
                                              Configs.domain)
    elseif Configs.domain ~= "" then
      value = format("login(%q, %q, nil, %q)", Configs.busref,
                                               Configs.entity,
                                               Configs.domain)
    else
      value = format("login(%q, %q)", Configs.busref,
                                      Configs.entity)
    end
    insert(executables, 1, {kind="code", value=value})
  end

  OPENBUS_EXITCODE = processargs(_G,
                                 Configs.noenvironment,
                                 Configs.interactive,
                                 executables,
                                 select(argidx, ...))
  _G.quit()
end
