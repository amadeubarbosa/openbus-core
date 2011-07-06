--
-- Configura��o do Servi�o de Controle de Acesso
--
-- $Id: AccessControlServerConfiguration.lua 88911 2009-03-05 02:26:09Z rcosme $
--
AccessControlServerConfiguration = {
  hostName = "localhost",
  hostPort = 2089,
  ldapHosts = {
    {name = "segall.tecgraf.puc-rio.br", port = 389,},
  },
  ldapSuffixes = {
    "",
  },
  certificatesDirectory = "certificates",
  privateKeyFile = "certificates/AccessControlService.key",
  monitorPrivateKeyFile = "certificates/ACSMonitor.key",
  accessControlServiceCertificateFile = "certificates/AccessControlService.crt",
  databaseDirectory = "credentials",
  administrators = {},
  --o tempo m�nimo do lease deve ser maior que 
  --o tempo m�ximo para o tratamento de falhas
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
    "core.services.accesscontrol.LDAPLoginPasswordValidator",
    "core.services.accesscontrol.TestLoginPasswordValidator",
  },
  adminMail = "root@localhost",
}
