--
-- Configuração do Serviço de Controle de Acesso
--
-- $Id$
--
AccessControlServerConfiguration = {
  hostName = "localhost",
  hostPort = 2089,
  ldapUrls = {
    "ldap://segall.tecgraf.puc-rio.br:389",
  },
  ldapSuffixes = {
    "",
  },
  certificatesDirectory = "certificates",
  privateKeyFile = "certificates/AccessControlService.key",
  monitorPrivateKeyFile = "certificates/ACSMonitor.key",
  accessControlServiceCertificateFile = "certificates/AccessControlService.crt",
  databaseDirectory = "credentials",
  administrators = {"tester"},
  --o tempo mínimo do lease deve ser maior que 
  --o tempo máximo para o tratamento de falhas
  --vide /conf/FTTimeOutConfiguration.lua
  lease = 180,
  logs = {
    service = {
      level = 5,
      file = "logs/access_control_service.log",
    },
    audit = {
      level = 1,
      file = "logs/access_control_service_audit.log",
    },
    perf = {
      level = 0,
    },
    oil = {
      level = 5,
      file = "logs/access_control_service_oil.log",
    },
  },
  validators = {
    "core.services.accesscontrol.ActiveDirectoryLoginValidator",
    "core.services.accesscontrol.TestLoginPasswordValidator",
  },
  adminMail = "root@localhost",
}
