local _G = require "_G"
local pcall = _G.pcall

local io = require "io"

local openbus = require "openbus"
local idl = require "openbus.core.idl"
local UnauthorizedOperation = idl.types.services.UnauthorizedOperation
local MissingCertificate = idl.types.services.access_control.MissingCertificate
local admidl = require "openbus.core.admin.idl"
local CertificateRegistry = admidl.types.services.access_control.admin.v1_0.CertificateRegistry
local InvalidCertificate = admidl.types.services.access_control.admin.v1_0.InvalidCertificate


local Check = require "latt.Check"

-- Configurações --------------------------------------------------------------
bushost, busport = ...
require "openbus.test.configs"
local host = bushost
local port = busport
local admin = admin
local adminPassword = admpsw
local dUser = user
local dPassword = password
local certificate = syscrt

-- Inicialização --------------------------------------------------------------
local orb = openbus.initORB()
local OpenBusContext = orb.OpenBusContext
do
  admidl.loadto(orb)
  function OpenBusContext:getCertificateRegistry()
    local conn = self:getCurrentConnection()
    if conn == nil or conn.login == nil then
      sysexthrow.NO_PERMISSION{
        completed = "COMPLETED_NO",
        minor = loginconst.NoLoginCode,
      }
    end
    local facet = conn.bus:getFacetByName("CertificateRegistry")
    return self.orb:narrow(facet, CertificateRegistry)
  end
end
local connprops = { accesskey = openbus.newKey() }

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
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
end

function NoPermissionCase.afterTestCase(self)
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
  self.conn = nil
end

function NoPermissionCase.testRegisterCertificateNoPermission(self)
  local certificates = OpenBusContext:getCertificateRegistry()
  local file = io.open(certificate)
  local cert = file:read("*a")
  file:close()
  local ok, err = pcall(certificates.registerCertificate, certificates, "random",
      cert)
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testGetCertificateNoPermission(self)
  local certificates = OpenBusContext:getCertificateRegistry()
  local ok, err = pcall(certificates.getCertificate, certificates, "random")
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testGetEntitiesWithCertificateNoPermission(self)
  local certificates = OpenBusContext:getCertificateRegistry()
  local ok, err = pcall(certificates.getEntitiesWithCertificate, certificates)
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testRemoveCertificateNoPermission(self)
  local certificates = OpenBusContext:getCertificateRegistry()
  local ok, err = pcall(certificates.removeCertificate, certificates, "random")
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)  
end

-------------------------------------
-- Caso de teste "INVALID PARAMETERS"
-------------------------------------

function InvalidParamCase.beforeTestCase(self)
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.certs = OpenBusContext:getCertificateRegistry()
end

function InvalidParamCase.afterTestCase(self)
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
  self.conn = nil
  self.certs = nil
end

function InvalidParamCase.testRegisterEmptyCertificate(self)
  local certs = self.certs
  local file = io.tmpfile()
  local read = file:read("*a")
  local ok, err = pcall(certs.registerCertificate, certs, "unknown", read)
  Check.assertTrue(not ok)
  Check.assertEquals(InvalidCertificate, err._repid)
  file:close()
end

function InvalidParamCase.testRegisterInvalidCertificate(self)
  local certs = self.certs
  local file = io.open(certificate)
  local read = file:read("*a")
  read = "\n--CORRUPTED!--\n" .. read
  local ok, err = pcall(certs.registerCertificate, certs, "unknown", read)
  Check.assertTrue(not ok)
  Check.assertEquals(InvalidCertificate, err._repid)
  file:close()
end

function InvalidParamCase.testInvalidGetCertificate(self)
  local certs = self.certs
  local ok, err = pcall(certs.getCertificate, certs, "unknown")
  Check.assertTrue(not ok)
  Check.assertEquals(MissingCertificate, err._repid)
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
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.certs = OpenBusContext:getCertificateRegistry()
end

function CRCase.afterTestCase(self)
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
  self.conn = nil
  self.certs = nil
end

function CRCase.testRegisterRemoveCertificate(self)
  local certs = self.certs
  local file = io.open(certificate)
  local read = file:read("*a")
  file:close()
  certs:registerCertificate("test-1", read)
  Check.assertTrue(certs:removeCertificate("test-1"))
end

function CRCase.testRegisterGetRemoveCertificate(self)
  local certs = self.certs
  local file = io.open(certificate)
  local read = file:read("*a")
  file:close()
  certs:registerCertificate("test-2", read)
  local result = certs:getCertificate("test-2")
  Check.assertTrue(read == result, "certificate file should be the same")
  Check.assertTrue(certs:removeCertificate("test-2"))
end

function CRCase.testRegisterCertificateTwice(self)
  local certs = self.certs
  local file = io.open(certificate)
  local read = file:read("*a")
  file:close()
  certs:registerCertificate("test-3", read)
  certs:registerCertificate("test-3", read)
  local result = certs:removeCertificate("test-3")
  Check.assertTrue(result)
  local result = certs:removeCertificate("test-3")
  Check.assertFalse(result)
end

function CRCase.testGetListWithManyEntitiesWithCertificate(self)
  local certs = self.certs
  -- get entities with previously registered certificates
  local previous = {}
  local prevcount
  for index, entity in ipairs(certs:getEntitiesWithCertificate()) do
    previous[entity] = true
    prevcount = index
  end
  -- register some new certificates
  local file = io.open(certificate)
  local read = file:read("*a")
  file:close()
  local count = 3
  local expected = {}
  for i = 1, count do
    local entity = "test-4_"..i
    expected[entity] = true
    certs:registerCertificate(entity, read)
  end
  -- check the new list inclue the new entities with registered certificates
  local list = certs:getEntitiesWithCertificate()
  Check.assertEquals(count+prevcount, #list)
  for _, entity in ipairs(list) do
    if not previous[entity] then
      Check.assertTrue(expected[entity])
      expected[entity] = nil
      certs:removeCertificate(entity)
    end
  end
end
