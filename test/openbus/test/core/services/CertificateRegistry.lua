local _G = require "_G"
local pcall = _G.pcall

local io = require "io"

local pubkey = require "lce.pubkey"

local openbus = require "openbus"
local idl = require "openbus.core.idl"
local srvtypes = idl.types.services
local logintypes = srvtypes.access_control

local Check = require "latt.Check"

-- Configurações --------------------------------------------------------------
bushost, busport = ...
require "openbus.util.testcfg"
local host = bushost
local port = busport
local admin = admin
local adminPassword = admpsw
local dUser = user
local dPassword = password
local certificate = syscrt

-- Inicialização --------------------------------------------------------------
local orb = openbus.initORB()
local connections = orb.OpenBusConnectionManager
local connprops = { privatekey = pubkey.create(idl.const.EncryptedBlockSize) }

-- Casos de Teste -------------------------------------------------------------
Suite = {}
Suite.Test1 = {}
Suite.Test2 = {}
Suite.Test3 = {}

-- Aliases
local NoPermissionCase = Suite.Test1
local InvalidParamCase = Suite.Test2
local CRCase = Suite.Test3

-- Testes do CertificateRegistry ----------------------------------------------

-- -- IDL operations
-- function CertificateRegistry:registerCertificate(entity, certificate)
-- function CertificateRegistry:getCertificate(entity)
-- function CertificateRegistry:removeCertificate(entity)

--------------------------------
-- Caso de teste "NO PERMISSION"
--------------------------------

function NoPermissionCase.beforeTestCase(self)
  local conn = connections:createConnection(host, port, connprops)
  connections:setDefaultConnection(conn)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
end

function NoPermissionCase.afterTestCase(self)
  self.conn:logout()
  connections:setDefaultConnection(nil)
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
  Check.assertEquals(srvtypes.UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testGetCertificateNoPermission(self)
  local certificates = self.conn.certificates
  local ok, err = pcall(certificates.getCertificate, certificates, "random")
  Check.assertTrue(not ok)
  Check.assertEquals(srvtypes.UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testRemoveCertificateNoPermission(self)
  local certificates = self.conn.certificates
  local ok, err = pcall(certificates.removeCertificate, certificates, "random")
  Check.assertTrue(not ok)
  Check.assertEquals(srvtypes.UnauthorizedOperation, err._repid)  
end

-------------------------------------
-- Caso de teste "INVALID PARAMETERS"
-------------------------------------

function InvalidParamCase.beforeTestCase(self)
  local conn = connections:createConnection(host, port, connprops)
  connections:setDefaultConnection(conn)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.certs = conn.certificates
end

function InvalidParamCase.afterTestCase(self)
  self.conn:logout()
  connections:setDefaultConnection(nil)
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
  local conn = connections:createConnection(host, port, connprops)
  connections:setDefaultConnection(conn)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.certs = conn.certificates
end

function CRCase.afterTestCase(self)
  self.conn:logout()
  connections:setDefaultConnection(nil)
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
