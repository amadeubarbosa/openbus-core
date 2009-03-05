--
-- Configuração do Serviço de Registro
--
-- $Id$
--
RegistryServerConfiguration = {
  accessControlServerHostName = "localhost",
  accessControlServerHostPort = 2089,
  privateKeyFile = "../certificates/RegistryService.key",
  accessControlServiceCertificateFile = "../certificates/AccessControlService.crt",
  databaseDirectory = "../offers",
  logLevel = 3,
  oilVerboseLevel = 1,
}
