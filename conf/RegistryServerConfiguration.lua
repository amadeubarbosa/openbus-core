--
-- Configura��o do Servi�o de Registro
--
-- $Id$
--
RegistryServerConfiguration = {
  accessControlServerHostName = "localhost",
  accessControlServerHostPort = 2089,
  privateKeyFile = "../certificates/RegistryService.key",
  accessControlServiceCertificateFile = "../certificates/AccessControlService.crt",
  logLevel = 3,
  oilVerboseLevel = 1,
}
