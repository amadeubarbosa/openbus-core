--
-- Configura��o do Servi�o de Sess�o
--
-- $Id: SessionServerConfiguration.lua 81077 2008-08-07 17:41:41Z rodrigoh $
--
SessionServerConfiguration = {
  accessControlServerHostName = "localhost",
  accessControlServerHostPort = 2089,
  privateKeyFile = "certificates/SessionService.key",
  accessControlServiceCertificateFile = "certificates/AccessControlService.crt",
  logLevel = 3,
  oilVerboseLevel = 1,
  administrators = {"tester"},
}
