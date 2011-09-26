--
-- Configura��o do Servi�o de Sess�o
--
-- $Id$
--
SessionServerConfiguration = {
  accessControlServerHostName = "localhost",
  accessControlServerHostPort = 2089,
  sessionServerHostName = "localhost",
  sessionServerHostPort = 2029,
  privateKeyFile = "certificates/SessionService.key",
  accessControlServiceCertificateFile = "certificates/AccessControlService.crt",
  logs = {
    service = {
      level = 4,
      file = "logs/session_service.log",
    },
    audit = {
      level = 1,
      file = "logs/session_service_audit.log",
    },
    oil = {
      level = 5,
      file = "logs/session_service_oil.log",
    },
  },
}
