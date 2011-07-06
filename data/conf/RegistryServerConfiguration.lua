--
-- Configuração do Serviço de Registro
--
-- $Id: RegistryServerConfiguration.lua 88911 2009-03-05 02:26:09Z rcosme $
--
RegistryServerConfiguration = {
  accessControlServerHostName = "localhost",
  accessControlServerHostPort = 2089,
  registryServerHostName = "localhost",
  registryServerHostPort = 2059,
  privateKeyFile = "certificates/RegistryService.key",
  accessControlServiceCertificateFile = "certificates/AccessControlService.crt",
  monitorPrivateKeyFile = "certificates/RGSMonitor.key",
  databaseDirectory = "offers",
  administrators = {},
  logs = {
    service = {
      level = 4,
      file = "logs/registry_service.log",
    },
    audit = {
      level = 1,
      file = "logs/registry_service_audit.log",
    },
    perf = {
      level = 0,
    },
    oil = {
      level = 5,
      file = "logs/registry_service_oil.log",
    },
  },
  adminMail = "root@localhost",
}
