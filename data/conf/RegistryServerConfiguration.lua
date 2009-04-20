--
-- Configuração do Serviço de Registro
--
-- $Id: RegistryServerConfiguration.lua 88911 2009-03-05 02:26:09Z rcosme $
--
RegistryServerConfiguration = {
--  accessControlServerHostName = "localhost",
--  accessControlServerHostPort = 2089,
  registryServerHost = "localhost:2089",
  registryServerHostName = "localhost",
  registryServerHostPort = 2089,
  privateKeyFile = "certificates/RegistryService.key",
  accessControlServiceCertificateFile = "certificates/AccessControlService.crt",
  databaseDirectory = "offers",
  logLevel = 4,
  oilVerboseLevel = 1,
}
