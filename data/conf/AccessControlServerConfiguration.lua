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
  logLevel = 4,
  oilVerboseLevel = 1,
}
