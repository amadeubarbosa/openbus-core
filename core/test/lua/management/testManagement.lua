--
-- Testes unit�rios do Servi�o de Governan�a
--
require "oil"
local orb = oil.orb
local oop = require "loop.base"

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

local scs = require "scs.core.base"

local Check = require "latt.Check"

-------------------------------------------------------------------------------
-- Faz login com o barramento e recupera as facetas de governan�a.
--
local login = "tester"
local password = "tester"

local function init(self)
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A vari�vel IDLPATH_DIR n�o foi definida.\n")
    os.exit(1)
  end
  oil.verbose:level(0)
  orb:loadidlfile(IDLPATH_DIR.."/v1_05/scs.idl")
  orb:loadidlfile(IDLPATH_DIR.."/v1_05/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/v1_05/registry_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/v1_04/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/v1_04/registry_service.idl")
  -- Instala o interceptador cliente
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  local config = assert(loadfile(DATA_DIR ..
    "/conf/advanced/InterceptorsConfiguration.lua"))()
  self.credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))

  -- Obt�m a configura��o do servi�o
  local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
  assert(loadfile(OPENBUS_HOME.."/data/conf/AccessControlServerConfiguration.lua"))()

  -- Obtem a face de governan�a
  local succ
  local ic = orb:newproxy("corbaloc::".. AccessControlServerConfiguration.hostName
                           ..":" .. AccessControlServerConfiguration.hostPort .."/openbus_v1_05",
    "synchronous", "IDL:scs/core/IComponent:1.0")
  local facet = ic:getFacet(
    "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
  self.acs = orb:narrow(facet,
    "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
  succ, self.credential = self.acs:loginByPassword(login, password)
  self.credentialManager:setValue(self.credential)
  --
  facet = ic:getFacet(
    "IDL:tecgraf/openbus/core/v1_05/access_control_service/IManagement:1.0")
  self.acsMgt = orb:narrow(facet,
    "IDL:tecgraf/openbus/core/v1_05/access_control_service/IManagement:1.0")
  self.acsMgt = orb:newproxy(self.acsMgt, "protected")
  --
  facet = ic:getFacetByName("IReceptacles")
  facet = orb:narrow(facet, "IDL:scs/core/IReceptacles:1.0")
  local conns = facet:getConnections("RegistryServiceReceptacle")
  ic = orb:narrow(conns[1].objref, "IDL:scs/core/IComponent:1.0")
  facet = ic:getFacet(
    "IDL:tecgraf/openbus/core/v1_05/registry_service/IRegistryService:1.0")
  self.rs = orb:narrow(facet,
    "IDL:tecgraf/openbus/core/v1_05/registry_service/IRegistryService:1.0")
  self.rs = orb:newproxy(self.rs, "protected")
  --
  facet = ic:getFacet("IDL:tecgraf/openbus/core/v1_05/registry_service/IManagement:1.0")
  self.rsMgt = orb:narrow(facet,
    "IDL:tecgraf/openbus/core/v1_05/registry_service/IManagement:1.0")
  self.rsMgt = orb:newproxy(self.rsMgt, "protected")
end

-------------------------------------------------------------------------------
-- Casos de teste.
--
Suite = {}
Suite.Test1 = {}
Suite.Test2 = {}
Suite.Test3 = {}
Suite.Test4 = {}
Suite.Test5 = {}
Suite.Test6 = {}
Suite.Test7 = {}

-- Aliases
local Test1 = Suite.Test1
local Test2 = Suite.Test2
local Test3 = Suite.Test3
local Test4 = Suite.Test4
local Test5 = Suite.Test5
local Test6 = Suite.Test6
local Test7 = Suite.Test7

--------------------------------------------------------------------------------
-- Testa o cadastro de sistemas da interface IManagement do ACS.
--

--
-- Pega refer�ncia para a interface de governan�a do ACS
--
function Test1:beforeTestCase()
  init(self)
  -- Dados para os testes
  self.systems = {}
  for i = 1, 10 do
    table.insert(self.systems, {
      id = string.format("system%.2d", i),
      description = string.format("System %.2d Description", i),
    })
  end
end

function Test1:afterTestCase()
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

--
-- Limpa a base para eventuais res�duos
--
function Test1:afterEachTest()
  for _, system in ipairs(self.systems) do
    self.acsMgt:removeSystem(system.id)
  end
end

function Test1:testAddGetRemoveSystem()
  local succ, err, added
  local system = self.systems[1]
  succ, err = self.acsMgt:addSystem(system.id, system.description)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt:getSystem(system.id)
  Check.assertTrue(succ)
  Check.assertEquals(system.id, added.id)
  Check.assertEquals(system.description, added.description)
  --
  succ, err = self.acsMgt:removeSystem(system.id)
  Check.assertTrue(succ)
end

function Test1:testAddGetRemoveSystems()
  local succ, err, list
  for _, system in ipairs(self.systems) do
    succ, err = self.acsMgt:addSystem(system.id, system.description)
    Check.assertTrue(succ)
  end
  --
  list = self.acsMgt:getSystems()
  for _, system in ipairs(self.systems) do
    succ = false
    for _, added in ipairs(list) do
      if added.id == system.id and added.description == system.description then
        succ = true
        break
      end
    end
    Check.assertTrue(succ)
  end
  --
  for _, system in ipairs(self.systems) do
    succ, err = self.acsMgt:removeSystem(system.id)
    Check.assertTrue(succ)
  end
end

function Test1:testAddSystem_SystemAlreadyExists()
  local system = self.systems[1]
  local succ, err = self.acsMgt:addSystem(system.id, system.description)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt:addSystem(system.id, system.description)
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemAlreadyExists:1.0")
  --
  succ, err = self.acsMgt:removeSystem(system.id)
  Check.assertTrue(succ)
end

function Test1:testRemoveSystem_SystemNonExistent()
  local succ, err = self.acsMgt:removeSystem("AnInvalidIdToRemove")
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemNonExistent:1.0")
end

function Test1:testSetSystemDescription()
  local succ, err, added
  local desc = "NewDescription"
  local system = self.systems[1]
  succ, err = self.acsMgt:addSystem(system.id, system.description)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt:setSystemDescription(system.id, desc)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt:getSystem(system.id)
  Check.assertTrue(succ)
  Check.assertEquals(system.id, added.id)
  Check.assertEquals(added.description, desc)
  --
  succ, err = self.acsMgt:removeSystem(system.id)
  Check.assertTrue(succ)
end

function Test1:testSetSystemDescription_SystemNonExistent()
  local succ, err = self.acsMgt:setSystemDescription("InvalidId",
    "New Description")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemNonExistent:1.0", err[1])
end

function Test1:testGetSystem_SystemNonExistent()
  local succ, err = self.acsMgt:getSystem("InvalidId")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemNonExistent:1.0", err[1])
end

--------------------------------------------------------------------------------
-- Testa o cadastro de implanta��o de sistemas da interface IManagement do ACS.
-- Tamb�m testa a exce��o de SystemInUse de removeSystem(), pois precisa
-- do cadastro de implanta��es.
--

function Test2:beforeTestCase()
  init(self)
  -- Dados para os testes
  self.certfiles = {"testManagement01.crt", "testManagement02.crt"}
  self.systems = {}
  self.deployments = {}
  for i = 1, 10 do
    local system = {
      id = string.format("system%.2d", i),
      description = string.format("System %.2d Description", i),
    }
    table.insert(self.systems, system)
    table.insert(self.deployments, {
      id = string.format("deployment%.2d", i),
      systemId = system.id,
      description = string.format("Deployment %.2d Description", i),
    })
    self.acsMgt:addSystem(system.id, system.description)
  end
end

function Test2:afterTestCase()
  for _, system in ipairs(self.systems) do
    self.acsMgt:removeSystem(system.id)
  end
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

function Test2:afterEachTest()
  for _, depl in ipairs(self.deployments) do
    self.acsMgt:removeSystemDeployment(depl.id)
  end
end

function Test2:testAddGetRemoveSystemDeployment()
  local f, cert, depl, succ, err, added
  f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  cert = f:read("*a")
  f:close()
  --
  depl = self.deployments[1]
  succ, err = self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt:getSystemDeployment(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(added.id, depl.id)
  Check.assertEquals(added.systemId, depl.systemId)
  Check.assertEquals(added.description, depl.description)
  --
  succ, added = self.acsMgt:getSystemDeploymentCertificate(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(added, cert)
  --
  succ, err = self.acsMgt:removeSystemDeployment(depl.id)
  Check.assertTrue(succ)
end

function Test2:testAddGetRemoveSystemDeployments()
  local f, cert, succ, err, list
  f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  cert = f:read("*a")
  f:close()
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
      depl.description, cert)
    Check.assertTrue(succ)
  end
  --
  list = self.acsMgt:getSystemDeployments()
  for _, depl in ipairs(self.deployments) do
    local tmp = false
    for _, added in ipairs(list) do
      if added.id == depl.id then
        succ, err = self.acsMgt:getSystemDeploymentCertificate(depl.id)
        tmp = succ and (err == cert) and
              (added.systemId == depl.systemId) and
              (added.description == depl.description)
        break
      end
    end
    Check.assertTrue(tmp)
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.acsMgt:removeSystemDeployment(depl.id)
    Check.assertTrue(succ)
  end
end

function Test2:testAddSystemDeployment_SystemDeploymentAlreadyExists()
  local f, cert, depl, succ, err
  f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  cert = f:read("*a")
  f:close()
  depl = self.deployments[1]
  succ, err = self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemDeploymentAlreadyExists:1.0",
    err[1])
  --
  succ, err = self.acsMgt:removeSystemDeployment(depl.id)
  Check.assertTrue(succ)
end

function Test2:testAddSystemDeployment_SystemNonExistent()
  local f, cert, depl, succ, err
  f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  cert = f:read("*a")
  f:close()
  depl = self.deployments[1]
  succ, err = self.acsMgt:addSystemDeployment(depl.id,
    "SystemIdDoesNotExist",
    depl.description, cert)
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemNonExistent:1.0")
end

function Test2:testAddSystemDeployment_InvalidCertificate()
  local depl, succ, err
  depl = self.deployments[1]
  succ, err = self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
    depl.description, "InvalidCertificate")
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/access_control_service/InvalidCertificate:1.0")
end

function Test2:testRemoveSystemDeployment_SystemDeploymentNonExistent()
  local succ, err = self.acsMgt:removeSystemDeployment("InvalidId")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemDeploymentNonExistent:1.0",
    err[1])
end

function Test2:testSetSystemDeploymentDescription()
  local f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  local cert = f:read("*a")
  f:close()
  local depl = self.deployments[1]
  local succ, err = self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertTrue(succ)
  --
  local desc = "New Description"
  succ, err = self.acsMgt:setSystemDeploymentDescription(depl.id, desc)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt:getSystemDeployment(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(added.id, depl.id)
  Check.assertEquals(added.systemId, depl.systemId)
  Check.assertEquals(added.description, desc)
  --
  succ, err = self.acsMgt:removeSystemDeployment(depl.id)
  Check.assertTrue(succ)
end

function Test2:testSetSystemDeploymentDescription_SystemDeploymentNonExistent()
  local desc = "New Description"
  local succ, err = self.acsMgt:setSystemDeploymentDescription("InvalidId",
    desc)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemDeploymentNonExistent:1.0",
    err[1])
end

function Test2:testGetSystemDeploymentCertificate_SystemDeploymentNonExistent()
  local succ, err = self.acsMgt:getSystemDeploymentCertificate("InvalidId")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemDeploymentNonExistent:1.0",
    err[1])
end

function Test2:testSetSystemDeploymentCertificate()
  local f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  local cert01 = f:read("*a")
  f:close()
  f = io.open(self.certfiles[2])
  Check.assertNotNil(f)
  local cert02 = f:read("*a")
  f:close()
  --
  local depl = self.deployments[1]
  local succ, err = self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert01)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt:setSystemDeploymentCertificate(depl.id, cert02)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt:getSystemDeploymentCertificate(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(added, cert02)
  --
  succ, err = self.acsMgt:removeSystemDeployment(depl.id)
  Check.assertTrue(succ)
end

function Test2:testSetSystemDeploymentCertificate_SystemDeploymentNonExistent()
  local f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  local cert = f:read("*a")
  f:close()
  --
  local succ, err = self.acsMgt:setSystemDeploymentCertificate("InvalidId",
    cert)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemDeploymentNonExistent:1.0",
    err[1])
end

function Test2:testSetSystemDeploymentCertificate_InvalidCertificate()
  local f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  local cert = f:read("*a")
  f:close()
  --
  local depl = self.deployments[1]
  local succ, err = self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertTrue(succ)
  --
  local succ, err = self.acsMgt:setSystemDeploymentCertificate(depl.id,
    "InvalidCertificate")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/InvalidCertificate:1.0", err[1])
end

function Test2:testGetSystemDeployment_SystemDeploymentNonExistent()
  local succ, err = self.acsMgt:getSystemDeployment("InvalidId")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemDeploymentNonExistent:1.0",
    err[1])
end

function Test2:testGetSystemDeploymentsBySystemId()
  local f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  local cert = f:read("*a")
  f:close()
  -- Cria um conjunto compartilhando o mesmo systemId
  local succ, err
  local deployments = {}
  local systemId = self.deployments[1].systemId
  for i, depl in ipairs(self.deployments) do
    local tmp = {}
    for k, v in pairs(depl) do
      tmp[k] = v
    end
    if (i%2 == 0) then
      tmp.systemId = systemId
    end
    table.insert(deployments, tmp)
    succ, err = self.acsMgt:addSystemDeployment(tmp.id, tmp.systemId,
      tmp.description, cert)
    Check.assertTrue(succ)
  end
  --
  local list = self.acsMgt:getSystemDeploymentsBySystemId(systemId)
  for _, added in ipairs(list) do
    local tmp = false
    for _, depl in ipairs(deployments) do
      if depl.id == added.id then
        succ, err = self.acsMgt:getSystemDeploymentCertificate(depl.id)
        tmp = succ and (added.description == depl.description) and
              (added.systemId == depl.systemId) and (err == cert)
        break
      end
    end
    Check.assertTrue(tmp)
  end
  --
  for _, depl in ipairs(deployments) do
    succ, err = self.acsMgt:removeSystemDeployment(depl.id)
    Check.assertTrue(succ)
  end
end

function Test2:testRemoveSystem_SystemInUse()
  local f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  local cert = f:read("*a")
  f:close()
  --
  local succ, err
  for _, depl in ipairs(self.deployments) do
    succ, err = self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
      depl.description, cert)
    Check.assertTrue(succ)
  end
  --
  for _, system in ipairs(self.systems) do
    succ, err = self.acsMgt:removeSystem(system.id)
    Check.assertFalse(succ)
    Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemInUse:1.0", err[1])
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.acsMgt:removeSystemDeployment(depl.id)
    Check.assertTrue(succ)
  end
end

--------------------------------------------------------------------------------
-- Testa o cadastro de interfaces da interface IManagement do RS.
--

function Test3:beforeTestCase()
  init(self)
  -- Dados para os testes
  self.ifaces = {}
  self.systems = {}
  self.deployments = {}
  local f = io.open("testManagement01.crt")
  local cert = f:read("*a")
  f:close()
  for i = 1, 10 do
    local system = {
      id = string.format("system%.2d", i),
      description = string.format("System %.2d Description", i),
    }
    local depl = {
      id = string.format("deployment%.2d", i),
      systemId = system.id,
      description = string.format("Deployment %.2d Description", i),
    }
    table.insert(self.systems, system)
    table.insert(self.deployments, depl)
    table.insert(self.ifaces, string.format("IDL:openbusidl/test%.2d:1.0", i))
    self.acsMgt:addSystem(system.id, system.description)
    self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
      depl.description, cert)
  end
end

function Test3:afterTestCase()
  for _, depl in ipairs(self.deployments) do
    self.acsMgt:removeSystemDeployment(depl.id)
  end
  for _, system in ipairs(self.systems) do
    self.acsMgt:removeSystem(system.id)
  end
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

function Test3:afterEachTest()
  for _, iface in ipairs(self.ifaces) do
    self.rsMgt:removeInterfaceIdentifier(iface)
  end
end

function Test3:testAddGetRemoveInterfaceIdentifier()
  local succ, err = self.rsMgt:addInterfaceIdentifier(self.ifaces[1])
  Check.assertTrue(succ)
  local list = self.rsMgt:getInterfaceIdentifiers()
  succ = false
  for _, iface in ipairs(list) do
    if iface == self.ifaces[1] then
      succ = true
      break
    end
  end
  Check.assertTrue(succ)
  succ, err = self.rsMgt:removeInterfaceIdentifier(self.ifaces[1])
  Check.assertTrue(succ)
end

function Test3:testAddInterfaceIdentifier_InterfaceIdentifierAlreadyExists()
  local succ, err = self.rsMgt:addInterfaceIdentifier(self.ifaces[1])
  Check.assertTrue(succ)
  succ, err = self.rsMgt:addInterfaceIdentifier(self.ifaces[1])
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/InterfaceIdentifierAlreadyExists:1.0",
    err[1])
  succ, err = self.rsMgt:removeInterfaceIdentifier(self.ifaces[1])
  Check.assertTrue(succ)
end

function Test3:testAddInterfaceIdentifier_InterfaceIdentifierNonExistent()
  succ, err = self.rsMgt:removeInterfaceIdentifier("InvalidInterface")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/InterfaceIdentifierNonExistent:1.0",
    err[1])
end

--------------------------------------------------------------------------------
-- Testa o cadastro das autoriza��es para implanta��es no RS.
--

function Test4:beforeTestCase()
  init(self)
  -- Dados para os testes
  self.ifaces = {}
  self.systems = {}
  self.deployments = {}
  local f = io.open("testManagement01.crt")
  local cert = f:read("*a")
  f:close()
  for i = 1, 10 do
    local system = {
      id = string.format("system%.2d", i),
      description = string.format("System %.2d Description", i),
    }
    local depl = {
      id = string.format("deployment%.2d", i),
      systemId = system.id,
      description = string.format("Deployment %.2d Description", i),
    }
    local iface = string.format("IDL:openbusidl/test%.2d:1.0", i)
    table.insert(self.systems, system)
    table.insert(self.deployments, depl)
    table.insert(self.ifaces, iface)
    self.acsMgt:addSystem(system.id, system.description)
    self.acsMgt:addSystemDeployment(depl.id, depl.systemId,
      depl.description, cert)
    self.rsMgt:addInterfaceIdentifier(iface)
  end
end

function Test4:afterTestCase()
  for _, iface in ipairs(self.ifaces) do
    self.rsMgt:removeInterfaceIdentifier(iface)
  end
  for _, depl in ipairs(self.deployments) do
    self.acsMgt:removeSystemDeployment(depl.id)
  end
  for _, system in ipairs(self.systems) do
    self.acsMgt:removeSystem(system.id)
  end
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

function Test4:afterEachTest()
  for _, depl in ipairs(self.deployments) do
    self.rsMgt:removeAuthorization(depl.id)
  end
end

function Test4:testGrantGetRemoveAuthorization()
  local succ, err, auth
  local depl = self.deployments[1]
  local iface = self.ifaces[1]
  succ, err = self.rsMgt:grant(depl.id, iface, true)
  Check.assertTrue(succ)
  --
  succ, auth = self.rsMgt:getAuthorization(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(auth.id, depl.id)
  Check.assertEquals(auth.type, "ATSystemDeployment")
  Check.assertTrue(#auth.authorized == 1)
  Check.assertTrue(auth.authorized[1] == iface)
  --
  succ, err = self.rsMgt:removeAuthorization(depl.id)
  Check.assertTrue(succ)
  --
  succ, err = self.rsMgt:getAuthorization(depl.id)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/AuthorizationNonExistent:1.0",
    err[1])
end

function Test4:testGrant_MemberNonExistent()
  local iface = self.ifaces[1]
  local succ, err = self.rsMgt:grant("InvalidId", iface, true)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/MemberNonExistent:1.0", err[1])
end

function Test4:testGrant_InterfaceIdentifierNonExistent()
  local depl = self.deployments[1]
  local succ, err = self.rsMgt:grant(depl.id, "InvalidId", true)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/InterfaceIdentifierNonExistent:1.0",
    err[1])
end

function Test4:testGrant_InvalidRegularExpression()
  local succ, err, auth
  local depl = self.deployments[1]
  local iface = "IDL:*invalid:1.0"
  succ, err = self.rsMgt:grant(depl.id, iface, true)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/InvalidRegularExpression:1.0",
    err[1])
end

function Test4:testGrantExpressions()
  local succ, err, auth
  local depl = self.deployments[1]
  local ifaces = {
    "IDL:*:*",
    "IDL:*:1.*",
    "IDL:*:1.0",
    "IDL:openbusidl/test/demo/hello:*",
    "IDL:openbusidl/test/demo/hello:1.0",
    "IDL:openbusidl/test/demo/hello*:1.0",
    "IDL:openbusidl/test/demo/hello*:*",
    "IDL:openbusidl/test/demo/hello*:1.*",
  }
  for _, iface in ipairs(ifaces) do
    succ, err = self.rsMgt:grant(depl.id, iface, false)
    Check.assertTrue(succ)
  end
  --
  succ, auth = self.rsMgt:getAuthorization(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(auth.id, depl.id)
  Check.assertEquals(auth.type, "ATSystemDeployment")
  for _, iface in ipairs(ifaces) do
    succ = false
    for _, added in ipairs(auth.authorized) do
      if iface == added then
        succ = true
        break
      end
    end
    Check.assertTrue(succ)
  end
  --
  succ, err = self.rsMgt:removeAuthorization(depl.id)
  Check.assertTrue(succ)
end

function Test4:testGrantRevokeGetAuthorization()
  local succ, err, auth
  local depl = self.deployments[1]
  for _, iface in ipairs(self.ifaces) do
    succ, err = self.rsMgt:grant(depl.id, iface, true)
    Check.assertTrue(succ)
  end
  --
  for _, iface in ipairs(self.ifaces) do
    succ, err = self.rsMgt:revoke(depl.id, iface)
    Check.assertTrue(succ)
  end
  --
  succ, err = self.rsMgt:getAuthorization(depl.id)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/AuthorizationNonExistent:1.0", err[1])
end

function Test4:testGetAuthorizations()
  local succ, err, auths
  local tmp = {}
  for _, depl in ipairs(self.deployments) do
    for _, iface in ipairs(self.ifaces) do
      succ, err = self.rsMgt:grant(depl.id, iface, true)
      Check.assertTrue(succ)
      local t = tmp[depl.id]
      if not t then
        t = {}
        tmp[depl.id] = t
      end
      t[#t+1] = iface
    end
  end
  --
  succ, auths = self.rsMgt:getAuthorizations()
  Check.assertTrue(succ)
  --
  -- Pode haver mais autoriza��es do que as cadastradas,
  -- ter cuidado na ordem da itera��o.
  --
  local found = false
  for id, ifaces in ipairs(tmp) do
    for _, auth in ipairs(auths) do
      if id == auth.id then
        found = true
        succ = false
        for _, iface in ipairs(ifaces) do
          for _, added in ipairs(auth.authorized) do
            if added == iface then
              succ = true
              break
            end
          end
          Check.assertTrue(succ)
        end
      end
    end
    Check.assertTrue(found)
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.rsMgt:removeAuthorization(depl.id)
    Check.assertTrue(succ)
    succ, err = self.rsMgt:getAuthorization(depl.id)
    Check.assertFalse(succ)
    Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/AuthorizationNonExistent:1.0", err[1])
  end
end

function Test4:testGetAuthorizationsByInterfaceId()
  local succ, err, auths
  local tmp = {}
  for i, depl in ipairs(self.deployments) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt:grant(depl.id, iface, true)
    Check.assertTrue(succ)
    tmp[depl.id] = iface
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, auths = self.rsMgt:getAuthorizationsByInterfaceId({
      tmp[depl.id]
    })
    local auth = auths[1]
    Check.assertTrue(succ)
    Check.assertTrue(#auths == 1)
    Check.assertEquals(auth.id, depl.id)
    Check.assertEquals(auth.type, "ATSystemDeployment")
    Check.assertTrue(#auth.authorized == 1)
    Check.assertEquals(auth.authorized[1], tmp[depl.id])
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.rsMgt:removeAuthorization(depl.id)
    Check.assertTrue(succ)
  end
end

function Test4:testGetAuthorizationsByInterfaceIdCommon()
  local succ, err, auths
  local ibase = "IDL:test/management/do/not/use/this/for/real:1.0"
  local tmp = {}
  for i, depl in ipairs(self.deployments) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt:grant(depl.id, iface, true)
    Check.assertTrue(succ)
    succ, err = self.rsMgt:grant(depl.id, ibase, false)
    Check.assertTrue(succ)
    tmp[depl.id] = iface
  end
  --
  succ, auths = self.rsMgt:getAuthorizationsByInterfaceId({ibase})
  Check.assertTrue(succ)
  Check.assertTrue(#auths == #self.deployments)
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.rsMgt:removeAuthorization(depl.id)
    Check.assertTrue(succ)
  end
end

function Test4:testGetAuthorizationsByInterfaceIdMulti()
  local succ, err, auths
  local ibase = "IDL:test/management/do/not/use/this/for/real:1.0"
  local tmp = {}
  for i, depl in ipairs(self.deployments) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt:grant(depl.id, iface, true)
    Check.assertTrue(succ)
    succ, err = self.rsMgt:grant(depl.id, ibase, false)
    Check.assertTrue(succ)
    tmp[depl.id] = iface
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, auths = self.rsMgt:getAuthorizationsByInterfaceId({
      ibase,
      tmp[depl.id]
    })
    local auth = auths[1]
    Check.assertTrue(succ)
    Check.assertTrue(#auths == 1)
    Check.assertEquals(auth.id, depl.id)
    Check.assertEquals(auth.type, "ATSystemDeployment")
    Check.assertTrue(#auth.authorized == 2)
    Check.assertTrue(((auth.authorized[1] == tmp[depl.id]) and
                      (auth.authorized[2] == ibase))
                     or
                     ((auth.authorized[2] == tmp[depl.id]) and
                      (auth.authorized[1] == ibase))
    )
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.rsMgt:removeAuthorization(depl.id)
    Check.assertTrue(succ)
  end
end

--------------------------------------------------------------------------------
-- Testa o cadastro de usu�rios da interface IManagement do ACS.
--

function Test5:beforeTestCase()
  init(self)
  -- Dados para os testes
  self.users = {}
  for i = 1, 10 do
    table.insert(self.users, {
      id = string.format("user%.2d", i),
      name = string.format("User %.2d", i),
    })
  end
end

function Test5:afterTestCase()
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

--
-- Limpa a base para eventuais res�duos
--
function Test5:afterEachTest()
  for _, user in ipairs(self.users) do
    self.acsMgt:removeUser(user.id)
  end
end

function Test5:testAddGetRemoveUser()
  local succ, err, added
  local user = self.users[1]
  succ, err = self.acsMgt:addUser(user.id, user.name)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt:getUser(user.id)
  Check.assertTrue(succ)
  Check.assertEquals(user.id, added.id)
  Check.assertEquals(user.name, added.name)
  --
  succ, err = self.acsMgt:removeUser(user.id)
  Check.assertTrue(succ)
end

function Test5:testAddGetRemoveUsers()
  local succ, err, list
  for _, user in ipairs(self.users) do
    succ, err = self.acsMgt:addUser(user.id, user.name)
    Check.assertTrue(succ)
  end
  --
  list = self.acsMgt:getUsers()
  for _, user in ipairs(self.users) do
    succ = false
    for _, added in ipairs(list) do
      if added.id == user.id and added.name == user.name then
        succ = true
        break
      end
    end
    Check.assertTrue(succ)
  end
  --
  for _, user in ipairs(self.users) do
    succ, err = self.acsMgt:removeUser(user.id)
    Check.assertTrue(succ)
  end
end

function Test5:testAddUser_UserAlreadyExists()
  local user = self.users[1]
  local succ, err = self.acsMgt:addUser(user.id, user.name)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt:addUser(user.id, user.name)
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/access_control_service/UserAlreadyExists:1.0")
  --
  succ, err = self.acsMgt:removeUser(user.id)
  Check.assertTrue(succ)
end

function Test5:testRemoveUser_UserNonExistent()
  local succ, err = self.acsMgt:removeUser("AnInvalidIdToRemove")
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/access_control_service/UserNonExistent:1.0")
end

function Test5:testSetUserName()
  local succ, err, added
  local name = "New Name For An User"
  local user = self.users[1]
  succ, err = self.acsMgt:addUser(user.id, user.name)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt:setUserName(user.id, name)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt:getUser(user.id)
  Check.assertTrue(succ)
  Check.assertEquals(user.id, added.id)
  Check.assertEquals(added.name, name)
  --
  succ, err = self.acsMgt:removeUser(user.id)
  Check.assertTrue(succ)
end

function Test5:testSetUserName_UserNonExistent()
  local succ, err = self.acsMgt:setUserName("InvalidId", "New Name For An User")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/UserNonExistent:1.0", err[1])
end

function Test5:testGetUser_UserNonExistent()
  local succ, err = self.acsMgt:getUser("InvalidId")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/access_control_service/UserNonExistent:1.0", err[1])
end

--------------------------------------------------------------------------------
-- Testa o cadastro das autoriza��es para usu�rios no RS.
--

function Test6:beforeTestCase()
  init(self)
  -- Dados para os testes
  self.ifaces = {}
  self.users = {}
  for i = 1, 10 do
    local user = {
      id = string.format("user%.2d", i),
      name = string.format("User %.2d", i),
    }
    local iface = string.format("IDL:openbusidl/test%.2d:1.0", i)
    table.insert(self.users, user)
    table.insert(self.ifaces, iface)
    self.acsMgt:addUser(user.id, user.name)
    self.rsMgt:addInterfaceIdentifier(iface)
  end
end

function Test6:afterTestCase()
  for _, iface in ipairs(self.ifaces) do
    self.rsMgt:removeInterfaceIdentifier(iface)
  end
  for _, user in ipairs(self.users) do
    self.acsMgt:removeUser(user.id)
  end
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

function Test6:afterEachTest()
  for _, user in ipairs(self.users) do
    self.rsMgt:removeAuthorization(user.id)
  end
end

function Test6:testGrantGetRemoveAuthorization()
  local succ, err, auth
  local user = self.users[1]
  local iface = self.ifaces[1]
  succ, err = self.rsMgt:grant(user.id, iface, true)
  Check.assertTrue(succ)
  --
  succ, auth = self.rsMgt:getAuthorization(user.id)
  Check.assertTrue(succ)
  Check.assertEquals(auth.id, user.id)
  Check.assertEquals(auth.type, "ATUser")
  Check.assertTrue(#auth.authorized == 1)
  Check.assertTrue(auth.authorized[1] == iface)
  --
  succ, err = self.rsMgt:removeAuthorization(user.id)
  Check.assertTrue(succ)
  --
  succ, err = self.rsMgt:getAuthorization(user.id)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/AuthorizationNonExistent:1.0",
    err[1])
end

function Test6:testGrant_MemberNonExistent()
  local iface = self.ifaces[1]
  local succ, err = self.rsMgt:grant("InvalidId", iface, true)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/MemberNonExistent:1.0", err[1])
end

function Test6:testGrant_InterfaceIdentifierNonExistent()
  local user = self.users[1]
  local succ, err = self.rsMgt:grant(user.id, "InvalidId", true)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/InterfaceIdentifierNonExistent:1.0",
    err[1])
end

function Test6:testGrant_InvalidRegularExpression()
  local succ, err, auth
  local user = self.users[1]
  local iface = "IDL:*invalid:1.0"
  succ, err = self.rsMgt:grant(user.id, iface, true)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/InvalidRegularExpression:1.0",
    err[1])
end

function Test6:testGrantExpressions()
  local succ, err, auth
  local user = self.users[1]
  local ifaces = {
    "IDL:*:*",
    "IDL:*:1.*",
    "IDL:*:1.0",
    "IDL:openbusidl/test/demo/hello:*",
    "IDL:openbusidl/test/demo/hello:1.0",
    "IDL:openbusidl/test/demo/hello*:1.0",
    "IDL:openbusidl/test/demo/hello*:*",
    "IDL:openbusidl/test/demo/hello*:1.*",
  }
  for _, iface in ipairs(ifaces) do
    succ, err = self.rsMgt:grant(user.id, iface, false)
    Check.assertTrue(succ)
  end
  --
  succ, auth = self.rsMgt:getAuthorization(user.id)
  Check.assertTrue(succ)
  Check.assertEquals(auth.id, user.id)
  Check.assertEquals(auth.type, "ATUser")
  for _, iface in ipairs(ifaces) do
    succ = false
    for _, added in ipairs(auth.authorized) do
      if iface == added then
        succ = true
        break
      end
    end
    Check.assertTrue(succ)
  end
  --
  succ, err = self.rsMgt:removeAuthorization(user.id)
  Check.assertTrue(succ)
end

function Test6:testGrantRevokeGetAuthorization()
  local succ, err, auth
  local user = self.users[1]
  for _, iface in ipairs(self.ifaces) do
    succ, err = self.rsMgt:grant(user.id, iface, true)
    Check.assertTrue(succ)
  end
  --
  for _, iface in ipairs(self.ifaces) do
    succ, err = self.rsMgt:revoke(user.id, iface)
    Check.assertTrue(succ)
  end
  --
  succ, err = self.rsMgt:getAuthorization(user.id)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/AuthorizationNonExistent:1.0", err[1])
end

function Test6:testGetAuthorizations()
  local succ, err, auths
  local tmp = {}
  for _, user in ipairs(self.users) do
    for _, iface in ipairs(self.ifaces) do
      succ, err = self.rsMgt:grant(user.id, iface, true)
      Check.assertTrue(succ)
      local t = tmp[user.id]
      if not t then
        t = {}
        tmp[user.id] = t
      end
      t[#t+1] = iface
    end
  end
  --
  succ, auths = self.rsMgt:getAuthorizations()
  Check.assertTrue(succ)
  --
  -- Pode haver mais autoriza��es do que as cadastradas,
  -- ter cuidado na ordem da itera��o.
  --
  local found = false
  for id, ifaces in ipairs(tmp) do
    for _, auth in ipairs(auths) do
      if id == auth.id then
        found = true
        succ = false
        for _, iface in ipairs(ifaces) do
          for _, added in ipairs(auth.authorized) do
            if added == iface then
              succ = true
              break
            end
          end
          Check.assertTrue(succ)
        end
      end
    end
    Check.assertTrue(found)
  end
  --
  for _, user in ipairs(self.users) do
    succ, err = self.rsMgt:removeAuthorization(user.id)
    Check.assertTrue(succ)
    succ, err = self.rsMgt:getAuthorization(user.id)
    Check.assertFalse(succ)
    Check.assertEquals("IDL:tecgraf/openbus/core/v1_05/registry_service/AuthorizationNonExistent:1.0", err[1])
  end
end

function Test6:testGetAuthorizationsByInterfaceId()
  local succ, err, auths
  local tmp = {}
  for i, user in ipairs(self.users) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt:grant(user.id, iface, true)
    Check.assertTrue(succ)
    tmp[user.id] = iface
  end
  --
  for _, user in ipairs(self.users) do
    succ, auths = self.rsMgt:getAuthorizationsByInterfaceId({
      tmp[user.id]
    })
    local auth = auths[1]
    Check.assertTrue(succ)
    Check.assertTrue(#auths == 1)
    Check.assertEquals(auth.id, user.id)
    Check.assertEquals(auth.type, "ATUser")
    Check.assertTrue(#auth.authorized == 1)
    Check.assertEquals(auth.authorized[1], tmp[user.id])
  end
  --
  for _, user in ipairs(self.users) do
    succ, err = self.rsMgt:removeAuthorization(user.id)
    Check.assertTrue(succ)
  end
end

function Test6:testGetAuthorizationsByInterfaceIdCommon()
  local succ, err, auths
  local ibase = "IDL:test/management/do/not/use/this/for/real:1.0"
  local tmp = {}
  for i, user in ipairs(self.users) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt:grant(user.id, iface, true)
    Check.assertTrue(succ)
    succ, err = self.rsMgt:grant(user.id, ibase, false)
    Check.assertTrue(succ)
    tmp[user.id] = iface
  end
  --
  succ, auths = self.rsMgt:getAuthorizationsByInterfaceId({ibase})
  Check.assertTrue(succ)
  Check.assertTrue(#auths == #self.users)
  --
  for _, user in ipairs(self.users) do
    succ, err = self.rsMgt:removeAuthorization(user.id)
    Check.assertTrue(succ)
  end
end

function Test6:testGetAuthorizationsByInterfaceIdMulti()
  local succ, err, auths
  local ibase = "IDL:test/management/do/not/use/this/for/real:1.0"
  local tmp = {}
  for i, user in ipairs(self.users) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt:grant(user.id, iface, true)
    Check.assertTrue(succ)
    succ, err = self.rsMgt:grant(user.id, ibase, false)
    Check.assertTrue(succ)
    tmp[user.id] = iface
  end
  --
  for _, user in ipairs(self.users) do
    succ, auths = self.rsMgt:getAuthorizationsByInterfaceId({
      ibase,
      tmp[user.id]
    })
    local auth = auths[1]
    Check.assertTrue(succ)
    Check.assertTrue(#auths == 1)
    Check.assertEquals(auth.id, user.id)
    Check.assertEquals(auth.type, "ATUser")
    Check.assertTrue(#auth.authorized == 2)
    Check.assertTrue(((auth.authorized[1] == tmp[user.id]) and
                      (auth.authorized[2] == ibase))
                     or
                     ((auth.authorized[2] == tmp[user.id]) and
                      (auth.authorized[1] == ibase))
    )
  end
  --
  for _, user in ipairs(self.users) do
    succ, err = self.rsMgt:removeAuthorization(user.id)
    Check.assertTrue(succ)
  end
end

--------------------------------------------------------------------------------
-- Testa o controle de ofertas no RS.
--

function Test7:beforeTestCase()
  init(self)
  --
  orb:loadidl([[
    interface IHello_v1 { };
    interface IHello_v2 { };
    interface IHello_v3 { };
  ]])
  -- Dados para os testes
  local Hello  = {
    -- Descri��o dos recept�culos
    receptacles = {},
    -- Descri��o das facetas
    facets = {
      IComponent = {
        name = "IComponent",
        interface_name = "IDL:scs/core/IComponent:1.0",
        class = scs.Component
      },
      IMetaInterface = {
        name = "IMetaInterface",
        interface_name = "IDL:scs/core/IMetaInterface:1.0",
        class = scs.MetaInterface
      },
      IHello_v1 = {
        name = "IHello_v1",
        interface_name = "IDL:IHello_v1:1.0",
        class = oop.class({}),
      },
      IHello_v2 = {
        name = "IHello_v2",
        interface_name = "IDL:IHello_v2:1.0",
        class = oop.class({}),
      },
      IHello_v3 = {
        name = "IHello_v3",
        interface_name = "IDL:IHello_v3:1.0",
        class = oop.class({}),
      },
    },
    -- ComponentId
    componentId = {
      name = "Hello",
      major_version = 1,
      minor_version = 0,
      patch_version = 0,
      platform_spec = "",
    },
  }
  --
  self.user = login
  self.acsMgt:addUser(self.user, self.user)
  --
  self.member = scs.newComponent(Hello.facets, Hello.receptacles,
    Hello.componentId)
end

function Test7:afterTestCase()
  self.acsMgt:removeUser(self.user)
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

function Test7:afterEachTest()
  self.rsId01 = nil
  self.rsId02 = nil
  self.rsId03 = nil
end

function Test7:afterEachTest()
  if type(self.rsId01) == "string" then
    self.rs:unregister(self.rsId01)
  end
  if type(self.rsId02) == "string" then
    self.rs:unregister(self.rsId02)
  end
  if type(self.rsId03) == "string" then
    self.rs:unregister(self.rsId03)
  end
  self.rsMgt:removeAuthorization(self.user)
end

function Test7:testGetOfferedInterfaces()
  local ifaces = {
    "IDL:IHello_v1:1.0",
    "IDL:IHello_v2:1.0",
    "IDL:IHello_v3:1.0",
  }

  local succ = self.rsMgt:grant(self.user, "IDL:*:*", false)
  Check.assertTrue(succ)

  succ, self.rsId01 = self.rs:register({
    member = self.member.IComponent,
    properties = {},
  })
  Check.assertTrue(succ)

  local offers = self.rsMgt:getOfferedInterfaces()
  Check.assertEquals(#offers, 1)
  Check.assertEquals(#offers[1].interfaces, 3)
  Check.assertEquals(offers[1].member, self.user)
  -- Cada oferta deve corresponder a uma �nica interface
  for _, offered in ipairs(offers[1].interfaces) do
    local pos = nil
    for n, iface in ipairs(ifaces) do
      if offered == iface then
        Check.assertNil(pos)  -- Repetiu?
        pos = n
      end
    end
    Check.assertNotNil(pos)   -- Existe?
    -- Remover para n�o repetir interface
    table.remove(ifaces, pos)
  end
end

function Test7:testGetOfferedInterfaces_MoreRegisters()
  local ifaces = {
    "IDL:IHello_v1:1.0",
    "IDL:IHello_v2:1.0",
    "IDL:IHello_v3:1.0",
  }

  local succ = self.rsMgt:grant(self.user, "IDL:*:*", false)
  Check.assertTrue(succ)

  succ, self.rsId01 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[1]},
      },
    }
  })
  Check.assertTrue(succ)
  succ, self.rsId02 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[2]},
      },
    }
  })
  Check.assertTrue(succ)
  succ, self.rsId03 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[3]},
      },
    }
  })
  Check.assertTrue(succ)

  local offers = self.rsMgt:getOfferedInterfaces()
  Check.assertEquals(#offers, 3)
  -- Cada oferta deve corresponder a uma �nica interface
  for _, offer in ipairs(offers) do
    Check.assertEquals(offer.member, self.user)
    Check.assertEquals(#offer.interfaces, 1)
    local pos = nil
    for n, iface in ipairs(ifaces) do
      if offer.interfaces[1] == iface then
        Check.assertNil(pos)  -- Repetiu?
        pos = n
      end
    end
    Check.assertNotNil(pos)   -- Existe?
    -- Remover para n�o repetir interface
    table.remove(ifaces, pos)
  end
end

function Test7:testGetOfferedInterfacesByMember()
  local ifaces = {
    "IDL:IHello_v1:1.0",
    "IDL:IHello_v2:1.0",
    "IDL:IHello_v3:1.0",
  }

  local succ = self.rsMgt:grant(self.user, "IDL:*:*", false)
  Check.assertTrue(succ)

  succ, self.rsId01 = self.rs:register({
    member = self.member.IComponent,
    properties = {},
  })
  Check.assertTrue(succ)

  local offers = self.rsMgt:getOfferedInterfacesByMember(self.user)
  Check.assertEquals(#offers, 1)
  Check.assertEquals(#offers[1].interfaces, 3)
  Check.assertEquals(offers[1].member, self.user)
  -- Cada oferta deve corresponder a uma �nica interface
  for _, offered in ipairs(offers[1].interfaces) do
    local pos = nil
    for n, iface in ipairs(ifaces) do
      if offered == iface then
        Check.assertNil(pos)  -- Repetiu?
        pos = n
      end
    end
    Check.assertNotNil(pos)   -- Existe?
    -- Remover para n�o repetir interface
    table.remove(ifaces, pos)
  end
end

function Test7:testGetOfferedInterfacesByMember_MoreRegisters()
  local ifaces = {
    "IDL:IHello_v1:1.0",
    "IDL:IHello_v2:1.0",
    "IDL:IHello_v3:1.0",
  }

  local succ = self.rsMgt:grant(self.user, "IDL:*:*", false)
  Check.assertTrue(succ)

  succ, self.rsId01 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[1]},
      },
    }
  })
  Check.assertTrue(succ)
  succ, self.rsId02 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[2]},
      },
    }
  })
  Check.assertTrue(succ)
  succ, self.rsId03 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[3]},
      },
    }
  })
  Check.assertTrue(succ)

  local offers = self.rsMgt:getOfferedInterfacesByMember(self.user)
  Check.assertEquals(#offers, 3)
  -- Cada oferta deve corresponder a uma �nica interface
  for _, offer in ipairs(offers) do
    Check.assertEquals(offer.member, self.user)
    Check.assertEquals(#offer.interfaces, 1)
    local pos = nil
    for n, iface in ipairs(ifaces) do
      if offer.interfaces[1] == iface then
        Check.assertNil(pos)  -- Repetiu?
        pos = n
      end
    end
    Check.assertNotNil(pos)   -- Existe?
    -- Remover para n�o repetir interface
    table.remove(ifaces, pos)
  end
end

function Test7:testGetUnauthorizedInterfaces()
  local ifaces = {
    "IDL:IHello_v1:1.0",
    "IDL:IHello_v2:1.0",
    "IDL:IHello_v3:1.0",
  }

  local succ = self.rsMgt:grant(self.user, "IDL:*:*", false)
  Check.assertTrue(succ)

  succ, self.rsId01 = self.rs:register({
    member = self.member.IComponent,
    properties = {},
  })
  Check.assertTrue(succ)

  local succ = self.rsMgt:revoke(self.user, "IDL:*:*")
  Check.assertTrue(succ)

  local offers = self.rsMgt:getUnauthorizedInterfaces()
  Check.assertEquals(#offers, 1)
  Check.assertEquals(#offers[1].interfaces, 3)
  Check.assertEquals(offers[1].member, self.user)
  -- Cada oferta deve corresponder a uma �nica interface
  for _, offered in ipairs(offers[1].interfaces) do
    local pos = nil
    for n, iface in ipairs(ifaces) do
      if offered == iface then
        Check.assertNil(pos)  -- Repetiu?
        pos = n
      end
    end
    Check.assertNotNil(pos)   -- Existe?
    -- Remover para n�o repetir interface
    table.remove(ifaces, pos)
  end
end

function Test7:testGetUnauthorizedInterfaces_MoreRegisters()
  local ifaces = {
    "IDL:IHello_v1:1.0",
    "IDL:IHello_v2:1.0",
    "IDL:IHello_v3:1.0",
  }

  local succ = self.rsMgt:grant(self.user, "IDL:*:*", false)
  Check.assertTrue(succ)

  succ, self.rsId01 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[1]},
      },
    }
  })
  Check.assertTrue(succ)
  succ, self.rsId02 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[2]},
      },
    }
  })
  Check.assertTrue(succ)
  succ, self.rsId03 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[3]},
      },
    }
  })
  Check.assertTrue(succ)

  local succ = self.rsMgt:revoke(self.user, "IDL:*:*")
  Check.assertTrue(succ)

  local offers = self.rsMgt:getUnauthorizedInterfaces()
  Check.assertEquals(#offers, 3)
  -- Cada oferta deve corresponder a uma �nica interface
  for _, offer in ipairs(offers) do
    Check.assertEquals(offer.member, self.user)
    Check.assertEquals(#offer.interfaces, 1)
    local pos = nil
    for n, iface in ipairs(ifaces) do
      if offer.interfaces[1] == iface then
        Check.assertNil(pos)  -- Repetiu?
        pos = n
      end
    end
    Check.assertNotNil(pos)   -- Existe?
    -- Remover para n�o repetir interface
    table.remove(ifaces, pos)
  end
end

function Test7:testGetUnauthorizedInterfacesByMember()
  local ifaces = {
    "IDL:IHello_v1:1.0",
    "IDL:IHello_v2:1.0",
    "IDL:IHello_v3:1.0",
  }

  local succ = self.rsMgt:grant(self.user, "IDL:*:*", false)
  Check.assertTrue(succ)

  succ, self.rsId01 = self.rs:register({
    member = self.member.IComponent,
    properties = {},
  })
  Check.assertTrue(succ)

  local succ = self.rsMgt:revoke(self.user, "IDL:*:*")
  Check.assertTrue(succ)

  local offers = self.rsMgt:getUnauthorizedInterfacesByMember(self.user)
  Check.assertEquals(#offers, 1)
  Check.assertEquals(#offers[1].interfaces, 3)
  Check.assertEquals(offers[1].member, self.user)
  -- Cada oferta deve corresponder a uma �nica interface
  for _, offered in ipairs(offers[1].interfaces) do
    local pos = nil
    for n, iface in ipairs(ifaces) do
      if offered == iface then
        Check.assertNil(pos)  -- Repetiu?
        pos = n
      end
    end
    Check.assertNotNil(pos)   -- Existe?
    -- Remover para n�o repetir interface
    table.remove(ifaces, pos)
  end
end

function Test7:testGetUnauthorizedInterfacesByMember_MoreRegisters()
  local ifaces = {
    "IDL:IHello_v1:1.0",
    "IDL:IHello_v2:1.0",
    "IDL:IHello_v3:1.0",
  }

  local succ = self.rsMgt:grant(self.user, "IDL:*:*", false)
  Check.assertTrue(succ)

  succ, self.rsId01 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[1]},
      },
    }
  })
  Check.assertTrue(succ)
  succ, self.rsId02 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[2]},
      },
    }
  })
  Check.assertTrue(succ)
  succ, self.rsId03 = self.rs:register({
    member = self.member.IComponent,
    properties = {
      {
        name  = "facets",
        value = {ifaces[3]},
      },
    }
  })
  Check.assertTrue(succ)

  local succ = self.rsMgt:revoke(self.user, "IDL:*:*")
  Check.assertTrue(succ)

  local offers = self.rsMgt:getUnauthorizedInterfacesByMember(self.user)
  Check.assertEquals(#offers, 3)
  -- Cada oferta deve corresponder a uma �nica interface
  for _, offer in ipairs(offers) do
    Check.assertEquals(offer.member, self.user)
    Check.assertEquals(#offer.interfaces, 1)
    local pos = nil
    for n, iface in ipairs(ifaces) do
      if offer.interfaces[1] == iface then
        Check.assertNil(pos)  -- Repetiu?
        pos = n
      end
    end
    Check.assertNotNil(pos)   -- Existe?
    -- Remover para n�o repetir interface
    table.remove(ifaces, pos)
  end
end

function Test7:testUnregister()
  local succ = self.rsMgt:grant(self.user, "IDL:*:*", false)
  Check.assertTrue(succ)

  local succ, id = self.rs:register({
    member = self.member.IComponent,
    properties = {},
  })
  Check.assertTrue(succ)

  local offers = self.rsMgt:getOfferedInterfacesByMember(self.user)
  Check.assertEquals(#offers, 1)
  Check.assertEquals(#offers[1].interfaces, 3)
  Check.assertEquals(offers[1].member, self.user)
  Check.assertEquals(offers[1].id, id)

  Check.assertTrue(self.rsMgt:unregister(offers[1].id))
  offers = self.rsMgt:getOfferedInterfacesByMember(self.user)
  Check.assertEquals(#offers, 0)
end
