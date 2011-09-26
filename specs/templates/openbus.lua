-- WARNING: this file will be included on installer.lua and some variables
-- like CONFIG, ERROR are filled there!
-- All global variables in this file, will become global in installer.lua too!

local platforms = require "tools.platforms"
local commands = platforms[TEC_SYSNAME]

Types = {}
Types.vector = {}
setmetatable(Types.vector,{
__call = function(self,t,save)
  local count = 1
  while (true) do
    print(CONFIG,"Property name: ".. t.name)
    print(CONFIG,"Informe o valor do vetor")
    if t.value then
      io.write("[" .. tostring(t.value[count] or "") .. "]> ")
    else
      io.write("[]> ")
    end
    local var = io.read("*l")
    if (var == nil or var == "") and t.value then
      var = t.value[count] or ""
    end
    if tonumber(var) then var = tonumber(var) end
    if not save[t.name] then save[t.name] = {} end
    table.insert(save[t.name],var)

    print(CONFIG,"Deseja informar outro elemento para o vetor '" .. t.name ..
        "'? sim ou nao?")
    io.write("[nao]> ")
    if not string.upper(io.read("*l")):find("SIM") then break end
    count = count + 1
  end
end
})

messages = {
  { name = "hostName",
    msg = "FQDN da máquina onde o Serviço de Acesso executará",
    type = "string",
    value = "localhost",
  },
  { name = "hostPort",
    msg = "Porta para o Serviço de Acesso",
    type = "number",
    value = 2089,
  },
  { name = "oilVerboseLevel",
    msg = "Nível de verbosidade do ORB OiL [de 0 a 5]",
    type = "number",
    value = 5,
  },
  { name = "logLevel",
    msg = "Nível de verbosidade do log do OpenBus [de 0 a 5]",
    type = "number",
    value = 5,
  },
  { name = "ldapUrls",
    msg = "URLs dos servidores LDAP (exemplo: ldaps://localhost:636, ldap://localhost:389)",
    type = "list",
    check = Types.vector,
    value = { "" },
  },
  { name = "ldapSuffixes",
    msg = "Sufixos UPN usados em servidores LDAP ActiveDirectory (exemplo: @tecgraf.puc-rio.br)",
    type = "list",
    check = Types.vector,
    value = { "" },
  },
-- OpenLDAP: exemplo de template de configuração para o instalador do PUTS configurar automaticamente
-- as informações sobre distinguished name necessárias pelo validador do OpenLDAP:
--[[
  { name = "ldapDNPatterns",
    msg = "Padrões de formação do DN em servidores LDAPv3 (exemplo: cn=%U,dc=tecgraf,dc=puc-rio,dc=br)",
    type = "list",
    check = Types.vector,
    value = { "" },
  },
]]
  { name = "administrators",
    msg = "Administradores do barramento.",
    type = "list",
    check = Types.vector,
    value = { },
  },
  { name = "adminMail",
    msg = "Email do administrador do barramento.",
    type = "string",
    value = "root@localhost",
  },
}

configure_action = function(answers, path, util)
  -- Loading original OpenBus file config (its loads for tables)
  local acsConfFile = path.."/data/conf/AccessControlServerConfiguration.lua"
  assert(loadfile(acsConfFile))()
  AccessControlServerConfiguration.hostName = answers.hostName
  AccessControlServerConfiguration.hostPort = answers.hostPort
  AccessControlServerConfiguration.ldapUrls = answers.ldapUrls
  AccessControlServerConfiguration.ldapSuffixes = answers.ldapSuffixes
  -- OpenLDAP: mapeando a propriedade no arquivo de configuração para a variável da resposta do instalador
  --AccessControlServerConfiguration.ldapDNPatterns = answers.ldapDNPatterns
  AccessControlServerConfiguration.administrators = answers.administrators
  AccessControlServerConfiguration.logs.service.level = answers.logLevel
  AccessControlServerConfiguration.logs.oil.level = answers.oilVerboseLevel
  AccessControlServerConfiguration.adminMail = answers.adminMail

  AccessControlServerConfiguration.lease = 180
  AccessControlServerConfiguration.validators = {
      "core.services.accesscontrol.ActiveDirectoryLoginValidator",
      -- OpenLDAP: adição automática do validador do OpenLDAP no arquivo de configuração gerado
      --"core.services.accesscontrol.LDAPv3LoginValidator",
      "core.services.accesscontrol.TestLoginPasswordValidator",
  }
  AccessControlServerConfiguration.certificatesDirectory = "certificates"
  AccessControlServerConfiguration.privateKeyFile =
      "certificates/AccessControlService.key"
  AccessControlServerConfiguration.databaseDirectory = "credentials"
  AccessControlServerConfiguration.monitorPrivateKeyFile =
      "certificates/ACSMonitor.key"
  AccessControlServerConfiguration.accessControlServiceCertificateFile =
      "certificates/AccessControlService.crt"

  local rgsConfFile = path.."/data/conf/RegistryServerConfiguration.lua"
  assert(loadfile(rgsConfFile))()
  RegistryServerConfiguration.accessControlServerHostName = answers.hostName
  RegistryServerConfiguration.accessControlServerHostPort = answers.hostPort

  local rsHostPort = answers.hostPort - 30
  RegistryServerConfiguration.registryServerHostName = answers.hostName
  RegistryServerConfiguration.registryServerHostPort = rsHostPort

  RegistryServerConfiguration.privateKeyFile =
      "certificates/RegistryService.key"
  RegistryServerConfiguration.accessControlServiceCertificateFile =
      "certificates/AccessControlService.crt"
  RegistryServerConfiguration.databaseDirectory = "offers"
  RegistryServerConfiguration.administrators = answers.administrators
  RegistryServerConfiguration.logs.service.level = answers.logLevel
  RegistryServerConfiguration.logs.oil.level = answers.oilVerboseLevel
  RegistryServerConfiguration.adminMail = answers.adminMail

  local sesConfFile = path.."/data/conf/SessionServerConfiguration.lua"
  assert(loadfile(sesConfFile))()
  -- this configuration depends of AccessControlServerConfiguration
  SessionServerConfiguration.accessControlServerHostName = answers.hostName
  SessionServerConfiguration.accessControlServerHostPort = answers.hostPort

  local ssHostPort = answers.hostPort - 60
  SessionServerConfiguration.sessionServerHostName = answers.hostName
  SessionServerConfiguration.sessionServerHostPort = ssHostPort

  SessionServerConfiguration.privateKeyFile = "certificates/SessionService.key"
  SessionServerConfiguration.accessControlServiceCertificateFile =
      "certificates/AccessControlService.crt"
  SessionServerConfiguration.logs.service.level = answers.logLevel
  SessionServerConfiguration.logs.oil.level = answers.oilVerboseLevel

  local ftACSConfFile = path .."/data/conf/ACSFaultToleranceConfiguration.lua"
  local loadConfig, err = loadfile(ftACSConfFile)
  if not loadConfig then
    error(err)
    os.exit(1)
  end
  ftACS = {}
  setfenv(loadConfig,ftACS)
  loadConfig()

  ftACS.ftconfig.hosts.ACS =
      generateCorbalocString(answers.hostName,answers.hostPort,"ACS_v1_05")
  ftACS.ftconfig.hosts.ACSIC =
      generateCorbalocString(answers.hostName,answers.hostPort,"openbus_v1_05")
  ftACS.ftconfig.hosts.LP =
      generateCorbalocString(answers.hostName,answers.hostPort,"LP_v1_05")

  ftACS.ftconfig.hosts.FTACS =
      generateCorbalocString(answers.hostName,answers.hostPort,"FTACS_v1_05")

  local ftRSConfFile = path .."/data/conf/RSFaultToleranceConfiguration.lua"
  loadConfig, err = loadfile(ftRSConfFile)
  if not loadConfig then
    error(err)
    os.exit(1)
  end
  ftRS = {}
  setfenv(loadConfig,ftRS)
  loadConfig()

  ftRS.ftconfig.hosts.RS =
    generateCorbalocString(answers.hostName,rsHostPort,"RS_v1_05")
  ftRS.ftconfig.hosts.FTRS =
    generateCorbalocString(answers.hostName,rsHostPort,"FTRS_v1_05")

  -- Persisting the configurations to temporary tree where the tarball was extracted
  util.serialize_table(acsConfFile,AccessControlServerConfiguration,
      "AccessControlServerConfiguration")
  util.serialize_table(rgsConfFile,RegistryServerConfiguration,
      "RegistryServerConfiguration")
  util.serialize_table(sesConfFile,SessionServerConfiguration,
      "SessionServerConfiguration")
  util.serialize_table(ftACSConfFile,ftACS.ftconfig,
      "ftconfig")
  util.serialize_table(ftRSConfFile,ftRS.ftconfig,
      "ftconfig")

  commands.exec(commands.cmd.mkdir .. path .. "/data/credentials")
  commands.exec(commands.cmd.mkdir .. path .. "/data/offers")

  return true
end

function generateCorbalocString(host,port,objKey)
  return { "corbaloc::"..host..":"..port.."/"..objKey, }
end
