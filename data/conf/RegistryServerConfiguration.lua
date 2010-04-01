--
-- Configuração do Serviço de Registro
--
-- $Id: RegistryServerConfiguration.lua 88911 2009-03-05 02:26:09Z rcosme $
--
RegistryServerConfiguration = {
  accessControlServerHostName = "localhost",
  accessControlServerHostPort = 2089,
  registryServerHostName = "localhost",
  registryServerHostPort = 2059,
  privateKeyFile = "certificates/RegistryService.key",
  accessControlServiceCertificateFile = "certificates/AccessControlService.crt",
  monitorPrivateKeyFile = "certificates/RGSMonitor.key",
  databaseDirectory = "offers",
  administrators = {},
  logLevel = 3,
  oilVerboseLevel = 1,
}
