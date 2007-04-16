--
-- Configuração do Serviço de Registro
--
-- $Id$
--
RegistryServerConfiguration = {
  accessControlServerHostName = "localhost",
  accessControlServerHostPort = 2089,
  accessControlServerKey = "ACS",
  privateKeyFile = "../certificates/RegistryService.key",
  accessControlServiceCertificateFile = "../certificates/AccessControlService.crt",
  verboseLevel = 3,
  oilVerboseLevel = 1,
}
