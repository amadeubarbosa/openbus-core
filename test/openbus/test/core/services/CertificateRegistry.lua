local _G = require "_G"
local io = _G.io
local pcall = _G.pcall
local pcall = _G.pcall
local string = _G.string

local oillog = require "oil.verbose"
local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local openbus = require "openbus"
local log = require "openbus.util.logger"
local server = require "openbus.util.server"
local setuplog = server.setuplog
local Check = require "latt.Check"

local idl = require "openbus.core.idl"
local logintypes = idl.types.services.access_control

-- Configurações --------------------------------------------------------------
local host = "localhost"
local port = 2089
local admin = "admin"
local adminPassword = "admin"
local dUser = "user"
local dPassword = "user"
local certificate = "teste.crt"
local sdklevel = 5
local oillevel = 0 

local scsutils = require ("scs.core.utils")()
local props = {}
scsutils:readProperties(props, "test.properties")
scsutils = nil

host = props:getTagOrDefault("host", host)
port = props:getTagOrDefault("port", port)
admin = props:getTagOrDefault("adminLogin", admin)
adminPassword = props:getTagOrDefault("adminPassword", adminPassword)
dUser = props:getTagOrDefault("login", dUser)
dPassword = props:getTagOrDefault("password", dPassword)
certificate = props:getTagOrDefault("certificate", certificate)
sdklevel = props:getTagOrDefault("sdkLogLevel", sdklevel)
oillevel = props:getTagOrDefault("oilLogLevel", oillevel)

-- Casos de Teste -------------------------------------------------------------
Suite = {}
Suite.Test1 = {}
Suite.Test2 = {}
Suite.Test3 = {}

-- Aliases
local NoPermissionCase = Suite.Test1
local InvalidParamCase = Suite.Test2
local CRCase = Suite.Test3

-- Funções auxiliares ---------------------------------------------------------


-- Inicialização --------------------------------------------------------------
setuplog(log, sdklevel)
setuplog(oillog, oillevel)

-- Testes do CertificateRegistry ----------------------------------------------

-- -- IDL operations
-- function CertificateRegistry:registerCertificate(entity, certificate)
-- function CertificateRegistry:getCertificate(entity)
-- function CertificateRegistry:removeCertificate(entity)

--------------------------------
-- Caso de teste "NO PERMISSION"
--------------------------------

function NoPermissionCase.beforeTestCase(self)
  local conn = openbus.connect(host, port)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
end

function NoPermissionCase.afterTestCase(self)
  self.conn:logout()
  self.conn = nil
end

function NoPermissionCase.testRegisterCertificateNoPermission(self)
  local certificates = self.conn.certificates
  local file = io.open(certificate)
  local cert = file:read("*a")
  file:close()
  local ok, err = pcall(certificates.registerCertificate, certificates, "random",
      cert)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, err._repid)
end

function NoPermissionCase.testGetCertificateNoPermission(self)
  local certificates = self.conn.certificates
  local ok, err = pcall(certificates.getCertificate, certificates, "random")
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, err._repid)
end

function NoPermissionCase.testRemoveCertificateNoPermission(self)
  local certificates = self.conn.certificates
  local file = io.open(certificate)
  local cert = file:read("*a")
  file:close()
  local ok, err = pcall(certificates.removeCertificate, certificates, "random")
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, err._repid)  
end

-------------------------------------
-- Caso de teste "INVALID PARAMETERS"
-------------------------------------

function InvalidParamCase.beforeTestCase(self)
  local conn = openbus.connect(host, port)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.certs = conn.certificates
end

function InvalidParamCase.afterTestCase(self)
  self.conn:logout()
  self.conn = nil
  self.certs = nil
end

function InvalidParamCase.testRegisterEmptyCertificate(self)
  local certs = self.certs
  local file = io.tmpfile()
  local read = file:read("*a")
  local ok, err = pcall(certs.registerCertificate, certs, "unknown", read)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.InvalidCertificate, err._repid)
  file:close()
end

function InvalidParamCase.testRegisterInvalidCertificate(self)
  local certs = self.certs
  local file = io.open(certificate)
  local read = file:read("*a")
  read = "\n--CORRUPTED!--\n" .. read
  local ok, err = pcall(certs.registerCertificate, certs, "unknown", read)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.InvalidCertificate, err._repid)
  file:close()
end

function InvalidParamCase.testInvalidGetCertificate(self)
  local certs = self.certs
  local ok, err = pcall(certs.getCertificate, certs, "unknown")
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.MissingCertificate, err._repid)
end

function InvalidParamCase.testInvalidRemoveCertificate(self)
  local certs = self.certs
  local ok, err = pcall(certs.removeCertificate, certs, "unknown")
  Check.assertTrue(ok)
  Check.assertFalse(err)  
end

-------------------------------------
-- Caso de teste "PADRÃO"
-------------------------------------

function CRCase.beforeTestCase(self)
  local conn = openbus.connect(host, port)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.certs = conn.certificates
end

function CRCase.afterTestCase(self)
  self.conn:logout()
  self.conn = nil
  self.certs = nil
end

function CRCase.testRegisterRemoveCertificate(self)
  local certs = self.certs
  local file = io.open(certificate)
  local read = file:read("*a")
  local ok, err = pcall(certs.registerCertificate, certs, "test-1", read)
  Check.assertTrue(ok)
  file:close()
  local ok, err = pcall(certs.removeCertificate, certs, "test-1")
  Check.assertTrue(ok)
  Check.assertTrue(err)
end

function CRCase.testRegisterGetRemoveCertificate(self)
  local certs = self.certs
  local file = io.open(certificate)
  local read = file:read("*a")
  local ok, err = pcall(certs.registerCertificate, certs, "test-2", read)
  Check.assertTrue(ok)
  file:close()
  local ok, err = pcall(certs.getCertificate, certs, "test-2")
  Check.assertTrue(ok)
  Check.assertTrue(read == err, "certificate file should be the same")
  local ok, err = pcall(certs.removeCertificate, certs, "test-2")
  Check.assertTrue(ok)
  Check.assertTrue(err)  
end

function CRCase.testRegisterCertificateTwice(self)
  local certs = self.certs
  local file = io.open(certificate)
  local read = file:read("*a")
  file:close()
  local ok, err = pcall(certs.registerCertificate, certs, "test-3", read)
  Check.assertTrue(ok)
  local ok, err = pcall(certs.registerCertificate, certs, "test-3", read)
  Check.assertTrue(ok)
  local ok, err = pcall(certs.removeCertificate, certs, "test-3")
  Check.assertTrue(ok)
  Check.assertTrue(err)
  local ok, err = pcall(certs.removeCertificate, certs, "test-3")
  Check.assertTrue(ok)
  Check.assertFalse(err)
end
