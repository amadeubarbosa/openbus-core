--
-- Configuração do Serviço de Sessão
--
-- $Id$
--
SessionServerConfiguration = {
  accessControlServerHostName = "localhost",
  accessControlServerHostPort = 2089,
  privateKeyFile = "../certificates/SessionService.key",
  accessControlServiceCertificateFile = "../certificates/AccessControlService.crt",
  logLevel = 3,
  oilVerboseLevel = 1,
}
