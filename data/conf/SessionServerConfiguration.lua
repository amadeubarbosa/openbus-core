--
-- Configuração do Serviço de Sessão
--
-- $Id: SessionServerConfiguration.lua 81077 2008-08-07 17:41:41Z rodrigoh $
--
SessionServerConfiguration = {
  accessControlServerHostName = "localhost",
  accessControlServerHostPort = 2089,
  sessionServerHostName = "localhost",
  sessionServerHostPort = 2029,
  privateKeyFile = "certificates/SessionService.key",
  accessControlServiceCertificateFile = "certificates/AccessControlService.crt",
  logLevel = 3,
  oilVerboseLevel = 1,
}
