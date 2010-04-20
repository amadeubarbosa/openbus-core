--
-- Configuração do Serviço de Controle de Acesso
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
  --o tempo mínimo do lease deve ser maior que 
  --o tempo máximo para o tratamento de falhas
  --vide /conf/FTTimeOutConfiguration.lua
  lease = 180,
  logLevel = 3,
  oilVerboseLevel = 1,
  validators = {
    "core.services.accesscontrol.LDAPLoginPasswordValidator",
    "core.services.accesscontrol.TestLoginPasswordValidator",
  },
  adminMail = "root@localhost",
}
