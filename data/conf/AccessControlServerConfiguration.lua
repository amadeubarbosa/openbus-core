--
-- Configuração do Serviço de Controle de Acesso
--
-- $Id: AccessControlServerConfiguration.lua 88911 2009-03-05 02:26:09Z rcosme $
--
AccessControlServerConfiguration = {
  hostName = "localhost",
  hostPort = 2089,
  ldapHosts = {
    {name = "segall.tecgraf.puc-rio.br", port = 389,},
  },
  ldapSuffixes = {
    "",
  },
  certificatesDirectory = "certificates",
  privateKeyFile = "certificates/AccessControlService.key",
  databaseDirectory = "credentials",
  administrators = {},
  lease = 60,
  logLevel = 3,
  oilVerboseLevel = 1,
  validators = {
    "core.services.accesscontrol.LDAPLoginPasswordValidator",
    "core.services.accesscontrol.TestLoginPasswordValidator",
  },
}
