--
-- Configuração do Serviço de Controle de Acesso
--
-- $Id$
--
AccessControlServerConfiguration = {
  hostName = "localhost",
  hostPort = 2089,
  ldapHostName = "segall.tecgraf.puc-rio.br",
  ldapHostPort = 389,
  certificatesDirectory = "../certificates",
  privateKeyFile = "../certificates/AccessControlService.key",
  databaseDirectory = "../credentials",
  verboseLevel = 3,
  oilVerboseLevel = 1,
}
