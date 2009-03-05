--
-- Configuração do Serviço de Controle de Acesso
--
-- $Id$
--
AccessControlServerConfiguration = {
  hostName = "localhost",
  hostPort = 2089,
  ldapHosts = {
--    {name = "segall.tecgraf.puc-rio.br", port = 389,},
  },
  ldapSuffixes = {
    "",
  },
  certificatesDirectory = "../certificates",
  privateKeyFile = "../certificates/AccessControlService.key",
  databaseDirectory = "../credentials",
  logLevel = 3,
  oilVerboseLevel = 5,
}
