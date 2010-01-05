--
-- Testes unitários do Serviço de Governança
--
require "oil"
local orb = oil.orb

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

local Check = require "latt.Check"

Suite = {}
Suite.Test1 = {}
Suite.Test2 = {}
Suite.Test3 = {}
Suite.Test4 = {}

--------------------------------------------------------------------------------
-- Testa o cadastro de sistemas da interface IManagement do ACS.
--

-- Alias
local Test1 = Suite.Test1

--
-- Pega referência para a interface de governança do ACS
--
function Test1:beforeTestCase()
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  oil.verbose:level(0)
  orb:loadidlfile(IDLPATH_DIR.."/scs.idl")
  orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")
  -- Instala o interceptador cliente
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  local config = assert(loadfile(DATA_DIR ..
    "/conf/advanced/InterceptorsConfiguration.lua"))()
  self.credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
  -- Obtem a face de governança
  local succ
  self.acs = orb:newproxy("corbaloc::localhost:2089/ACS", 
    "IDL:openbusidl/acs/IAccessControlService:1.0")
  succ, self.credential = self.acs:loginByPassword("tester", "tester")
  self.credentialManager:setValue(self.credential)
  local ic = self.acs:_component()
  ic = orb:narrow(ic, "IDL:scs/core/IComponent:1.0")
  self.acsMgt = ic:getFacetByName("IManagement")
  self.acsMgt = orb:narrow(self.acsMgt, "IDL:openbusidl/acs/IManagement:1.0")
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
-- Limpa a base para eventuais resíduos
--
function Test1:afterEachTest()
  for _, system in ipairs(self.systems) do
    self.acsMgt.__try:removeSystem(system.id)
  end
end

function Test1:testAddGetRemoveSystem()
  local succ, err, added
  local system = self.systems[1]
  succ, err = self.acsMgt.__try:addSystem(system.id, system.description)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt.__try:getSystemById(system.id)
  Check.assertTrue(succ)
  Check.assertEquals(system.id, added.id)
  Check.assertEquals(system.description, added.description)
  --
  succ, err = self.acsMgt.__try:removeSystem(system.id)
  Check.assertTrue(succ)
end

function Test1:testAddGetRemoveSystems()
  local succ, err, list
  for _, system in ipairs(self.systems) do
    succ, err = self.acsMgt.__try:addSystem(system.id, system.description)
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
    succ, err = self.acsMgt.__try:removeSystem(system.id)
    Check.assertTrue(succ)
  end
end

function Test1:testAddSystem_SystemAlreadyExists()
  local system = self.systems[1]
  local succ, err = self.acsMgt.__try:addSystem(system.id, system.description)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt.__try:addSystem(system.id, system.description)
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:openbusidl/acs/SystemAlreadyExists:1.0")
  --
  succ, err = self.acsMgt.__try:removeSystem(system.id)
  Check.assertTrue(succ)
end

function Test1:testRemoveSystem_SystemNonExistent()
  local succ, err = self.acsMgt.__try:removeSystem("AnInvalidIdToRemove")
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:openbusidl/acs/SystemNonExistent:1.0")
end

function Test1:testSetSystemDescription()
  local succ, err, added
  local desc = "NewDescription"
  local system = self.systems[1]
  succ, err = self.acsMgt.__try:addSystem(system.id, system.description)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt.__try:setSystemDescription(system.id, desc)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt.__try:getSystemById(system.id)
  Check.assertTrue(succ)
  Check.assertEquals(system.id, added.id)
  Check.assertEquals(added.description, desc)
  --
  succ, err = self.acsMgt.__try:removeSystem(system.id)
  Check.assertTrue(succ)
end

function Test1:testSetSystemDescription_SystemNonExistent()
  local succ, err = self.acsMgt.__try:setSystemDescription("InvalidId", 
    "New Description")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/acs/SystemNonExistent:1.0", err[1])
end

function Test1:testGetSystemById_SystemNonExistent()
  local succ, err = self.acsMgt.__try:getSystemById("InvalidId")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/acs/SystemNonExistent:1.0", err[1])
end

--------------------------------------------------------------------------------
-- Testa o cadastro de implantação de sistemas da interface IManagement do ACS.
-- Também testa a exceção de SystemInUse de removeSystem(), pois precisa
-- do cadastro de implantações.
--

-- Alias
local Test2 = Suite.Test2

function Test2:beforeTestCase()
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  oil.verbose:level(0)
  orb:loadidlfile(IDLPATH_DIR.."/scs.idl")
  orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")
  -- Instala o interceptador cliente
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  local config = assert(loadfile(DATA_DIR ..
    "/conf/advanced/InterceptorsConfiguration.lua"))()
  self.credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
  -- Obtem a face de governança
  local succ
  self.acs = orb:newproxy("corbaloc::localhost:2089/ACS", 
    "IDL:openbusidl/acs/IAccessControlService:1.0")
  succ, self.credential = self.acs:loginByPassword("tester", "tester")
  self.credentialManager:setValue(self.credential)
  local ic = self.acs:_component()
  ic = orb:narrow(ic, "IDL:scs/core/IComponent:1.0")
  self.acsMgt = ic:getFacetByName("IManagement")
  self.acsMgt = orb:narrow(self.acsMgt, "IDL:openbusidl/acs/IManagement:1.0")
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
    self.acsMgt.__try:addSystem(system.id, system.description)
  end
end

function Test2:afterTestCase()
  for _, system in ipairs(self.systems) do
    self.acsMgt.__try:removeSystem(system.id)
  end
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

function Test2:afterEachTest()
  for _, depl in ipairs(self.deployments) do
    self.acsMgt.__try:removeSystemDeployment(depl.id)
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
  succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt.__try:getSystemDeployment(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(added.id, depl.id)
  Check.assertEquals(added.systemId, depl.systemId)
  Check.assertEquals(added.description, depl.description)
  --
  succ, added = self.acsMgt.__try:getSystemDeploymentCertificate(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(added, cert)
  --
  succ, err = self.acsMgt.__try:removeSystemDeployment(depl.id)
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
    succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
      depl.description, cert)
    Check.assertTrue(succ)
  end
  --
  list = self.acsMgt:getSystemDeployments()
  for _, depl in ipairs(self.deployments) do
    local tmp = false
    for _, added in ipairs(list) do
      if added.id == depl.id then
        succ, err = self.acsMgt.__try:getSystemDeploymentCertificate(depl.id)
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
    succ, err = self.acsMgt.__try:removeSystemDeployment(depl.id)
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
  succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/acs/SystemDeploymentAlreadyExists:1.0",
    err[1])
  --
  succ, err = self.acsMgt.__try:removeSystemDeployment(depl.id)
  Check.assertTrue(succ)
end

function Test2:testAddSystemDeployment_SystemNonExistent()
  local f, cert, depl, succ, err
  f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  cert = f:read("*a")
  f:close()
  depl = self.deployments[1]
  succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, 
    "SystemIdDoesNotExist",
    depl.description, cert)
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:openbusidl/acs/SystemNonExistent:1.0")
end

function Test2:testAddSystemDeployment_InvalidCertificate()
  local depl, succ, err
  depl = self.deployments[1]
  succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
    depl.description, "InvalidCertificate")
  Check.assertFalse(succ)
  Check.assertEquals(err[1], "IDL:openbusidl/acs/InvalidCertificate:1.0")
end

function Test2:testRemoveSystemDeployment_SystemDeploymentNonExistent()
  local succ, err = self.acsMgt.__try:removeSystemDeployment("InvalidId")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0",
    err[1])
end

function Test2:testSetSystemDeploymentDescription()
  local f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  local cert = f:read("*a")
  f:close()
  local depl = self.deployments[1]
  local succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertTrue(succ)
  --
  local desc = "New Description"
  succ, err = self.acsMgt.__try:setSystemDeploymentDescription(depl.id, desc)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt.__try:getSystemDeployment(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(added.id, depl.id)
  Check.assertEquals(added.systemId, depl.systemId)
  Check.assertEquals(added.description, desc)
  --
  succ, err = self.acsMgt.__try:removeSystemDeployment(depl.id)
  Check.assertTrue(succ)
end

function Test2:testSetSystemDeploymentDescription_SystemDeploymentNonExistent()
  local desc = "New Description"
  local succ, err = self.acsMgt.__try:setSystemDeploymentDescription("InvalidId",
    desc)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0",
    err[1])
end

function Test2:testGetSystemDeploymentCertificate_SystemDeploymentNonExistent()
  local succ, err = self.acsMgt.__try:getSystemDeploymentCertificate("InvalidId")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0",
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
  local succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert01)
  Check.assertTrue(succ)
  --
  succ, err = self.acsMgt.__try:setSystemDeploymentCertificate(depl.id, cert02)
  Check.assertTrue(succ)
  --
  succ, added = self.acsMgt.__try:getSystemDeploymentCertificate(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(added, cert02)
  --
  succ, err = self.acsMgt.__try:removeSystemDeployment(depl.id)
  Check.assertTrue(succ)
end

function Test2:testSetSystemDeploymentCertificate_SystemDeploymentNonExistent()
  local f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  local cert = f:read("*a")
  f:close()
  --
  local succ, err = self.acsMgt.__try:setSystemDeploymentCertificate("InvalidId", 
    cert)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0", 
    err[1])
end

function Test2:testSetSystemDeploymentCertificate_InvalidCertificate()
  local f = io.open(self.certfiles[1])
  Check.assertNotNil(f)
  local cert = f:read("*a")
  f:close()
  --
  local depl = self.deployments[1]
  local succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
    depl.description, cert)
  Check.assertTrue(succ)
  --
  local succ, err = self.acsMgt.__try:setSystemDeploymentCertificate(depl.id,
    "InvalidCertificate")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/acs/InvalidCertificate:1.0", err[1])
end

function Test2:testGetSystemDeployment_SystemDeploymentNonExistent()
  local succ, err = self.acsMgt.__try:getSystemDeployment("InvalidId")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0",
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
    succ, err = self.acsMgt.__try:addSystemDeployment(tmp.id, tmp.systemId,
      tmp.description, cert)
    Check.assertTrue(succ)
  end
  --
  local list = self.acsMgt:getSystemDeploymentsBySystemId(systemId)
  for _, added in ipairs(list) do
    local tmp = false
    for _, depl in ipairs(deployments) do
      if depl.id == added.id then
        succ, err = self.acsMgt.__try:getSystemDeploymentCertificate(depl.id)
        tmp = succ and (added.description == depl.description) and
              (added.systemId == depl.systemId) and (err == cert)
        break
      end
    end
    Check.assertTrue(tmp)
  end
  --
  for _, depl in ipairs(deployments) do
    succ, err = self.acsMgt.__try:removeSystemDeployment(depl.id)
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
    succ, err = self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
      depl.description, cert)
    Check.assertTrue(succ)
  end
  --
  for _, system in ipairs(self.systems) do
    succ, err = self.acsMgt.__try:removeSystem(system.id)
    Check.assertFalse(succ)
    Check.assertEquals("IDL:openbusidl/acs/SystemInUse:1.0", err[1])
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.acsMgt.__try:removeSystemDeployment(depl.id)
    Check.assertTrue(succ)
  end
end

--------------------------------------------------------------------------------
-- Testa o cadastro de interfaces da interface IManagement do RS.
--

-- Alias
local Test3 = Suite.Test3

function Test3:beforeTestCase()
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  oil.verbose:level(0)
  orb:loadidlfile(IDLPATH_DIR.."/scs.idl")
  orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/registry_service.idl")
  -- Instala o interceptador cliente
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  local config = assert(loadfile(DATA_DIR ..
    "/conf/advanced/InterceptorsConfiguration.lua"))()
  self.credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
  -- Obtem a face de governança
  local succ
  self.acs = orb:newproxy("corbaloc::localhost:2089/ACS", 
    "IDL:openbusidl/acs/IAccessControlService:1.0")
  succ, self.credential = self.acs:loginByPassword("tester", "tester")
  self.credentialManager:setValue(self.credential)
  local acsIComp = self.acs:_component()
  acsIComp = orb:narrow(acsIComp, "IDL:scs/core/IComponent:1.0")
  self.acsMgt = acsIComp:getFacetByName("IManagement")
  self.acsMgt = orb:narrow(self.acsMgt, "IDL:openbusidl/acs/IManagement:1.0")
  local acsIRecept = acsIComp:getFacetByName("IReceptacles")
  acsIRecept = orb:narrow(acsIRecept, "IDL:scs/core/IReceptacles:1.0")
  local conns = acsIRecept:getConnections("RegistryServiceReceptacle")
  local rsIComp = orb:narrow(conns[1].objref, "IDL:scs/core/IComponent:1.0")
  self.rsMgt = rsIComp:getFacetByName("IManagement")
  self.rsMgt = orb:narrow(self.rsMgt, "IDL:openbusidl/rs/IManagement:1.0")
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
    self.acsMgt.__try:addSystem(system.id, system.description)
    self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
      depl.description, cert)
  end
end

function Test3:afterTestCase()
  for _, depl in ipairs(self.deployments) do
    self.acsMgt.__try:removeSystemDeployment(depl.id)
  end
  for _, system in ipairs(self.systems) do
    self.acsMgt.__try:removeSystem(system.id)
  end
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

function Test3:afterEachTest()
  for _, iface in ipairs(self.ifaces) do
    self.rsMgt.__try:removeInterfaceIdentifier(iface)
  end
end

function Test3:testAddGetRemoveInterfaceIdentifier()
  local succ, err = self.rsMgt.__try:addInterfaceIdentifier(self.ifaces[1])
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
  succ, err = self.rsMgt.__try:removeInterfaceIdentifier(self.ifaces[1])
  Check.assertTrue(succ)
end

function Test3:testAddInterfaceIdentifier_InterfaceIdentifierAlreadyExists()
  local succ, err = self.rsMgt.__try:addInterfaceIdentifier(self.ifaces[1])
  Check.assertTrue(succ)
  succ, err = self.rsMgt.__try:addInterfaceIdentifier(self.ifaces[1])
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/rs/InterfaceIdentifierAlreadyExists:1.0",
    err[1])
  succ, err = self.rsMgt.__try:removeInterfaceIdentifier(self.ifaces[1])
  Check.assertTrue(succ)
end

function Test3:testAddInterfaceIdentifier_InterfaceIdentifierNonExistent()
  succ, err = self.rsMgt.__try:removeInterfaceIdentifier("InvalidInterface")
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/rs/InterfaceIdentifierNonExistent:1.0",
    err[1])
end

--------------------------------------------------------------------------------
-- Testa o cadastro das autorizações do RS.
--

-- Alias
local Test4 = Suite.Test4

function Test4:beforeTestCase()
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  oil.verbose:level(0)
  orb:loadidlfile(IDLPATH_DIR.."/scs.idl")
  orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/registry_service.idl")
  -- Instala o interceptador cliente
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  local config = assert(loadfile(DATA_DIR ..
    "/conf/advanced/InterceptorsConfiguration.lua"))()
  self.credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
  -- Obtem a face de governança
  local succ
  self.acs = orb:newproxy("corbaloc::localhost:2089/ACS", 
    "IDL:openbusidl/acs/IAccessControlService:1.0")
  succ, self.credential = self.acs:loginByPassword("tester", "tester")
  self.credentialManager:setValue(self.credential)
  local acsIComp = self.acs:_component()
  acsIComp = orb:narrow(acsIComp, "IDL:scs/core/IComponent:1.0")
  self.acsMgt = acsIComp:getFacetByName("IManagement")
  self.acsMgt = orb:narrow(self.acsMgt, "IDL:openbusidl/acs/IManagement:1.0")
  local acsIRecept = acsIComp:getFacetByName("IReceptacles")
  acsIRecept = orb:narrow(acsIRecept, "IDL:scs/core/IReceptacles:1.0")
  local conns = acsIRecept:getConnections("RegistryServiceReceptacle")
  local rsIComp = orb:narrow(conns[1].objref, "IDL:scs/core/IComponent:1.0")
  self.rsMgt = rsIComp:getFacetByName("IManagement")
  self.rsMgt = orb:narrow(self.rsMgt, "IDL:openbusidl/rs/IManagement:1.0")
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
    self.acsMgt.__try:addSystem(system.id, system.description)
    self.acsMgt.__try:addSystemDeployment(depl.id, depl.systemId,
      depl.description, cert)
    self.rsMgt.__try:addInterfaceIdentifier(iface)
  end
end

function Test4:afterTestCase()
  for _, iface in ipairs(self.ifaces) do
    self.rsMgt.__try:removeInterfaceIdentifier(iface)
  end
  for _, depl in ipairs(self.deployments) do
    self.acsMgt.__try:removeSystemDeployment(depl.id)
  end
  for _, system in ipairs(self.systems) do
    self.acsMgt.__try:removeSystem(system.id)
  end
  if (self.credentialManager:hasValue()) then
    self.acs:logout(self.credential)
    self.credentialManager:invalidate()
  end
end

function Test4:afterEachTest()
  for _, depl in ipairs(self.deployments) do
    self.rsMgt.__try:removeAuthorization(depl.id)
  end
end

function Test4:testGrantGetRemoveAuthorization()
  local succ, err, auth
  local depl = self.deployments[1]
  local iface = self.ifaces[1]
  succ, err = self.rsMgt.__try:grant(depl.id, iface, true)
  Check.assertTrue(succ)
  --
  succ, auth = self.rsMgt.__try:getAuthorization(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(auth.deploymentId, depl.id)
  Check.assertEquals(auth.systemId, depl.systemId)
  Check.assertTrue(#auth.authorized == 1)
  Check.assertTrue(auth.authorized[1] == iface)
  --
  succ, err = self.rsMgt.__try:removeAuthorization(depl.id)
  Check.assertTrue(succ)
  --
  succ, err = self.rsMgt.__try:getAuthorization(depl.id)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/rs/AuthorizationNonExistent:1.0",
    err[1])
end

function Test4:testGrant_SystemDeploymentNonExistent()
  local iface = self.ifaces[1]
  local succ, err = self.rsMgt.__try:grant("InvalidId", iface, true)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/rs/SystemDeploymentNonExistent:1.0", 
    err[1])
end

function Test4:testGrant_InterfaceIdentifierNonExistent()
  local depl = self.deployments[1]
  local succ, err = self.rsMgt.__try:grant(depl.id, "InvalidId", true)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/rs/InterfaceIdentifierNonExistent:1.0", 
    err[1])
end

function Test4:testGrant_InvalidRegularExpression()
  local succ, err, auth
  local depl = self.deployments[1]
  local iface = "IDL:*invalid:1.0"
  succ, err = self.rsMgt.__try:grant(depl.id, iface, true)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/rs/InvalidRegularExpression:1.0", 
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
    succ, err = self.rsMgt.__try:grant(depl.id, iface, false)
    Check.assertTrue(succ)
  end
  --
  succ, auth = self.rsMgt.__try:getAuthorization(depl.id)
  Check.assertTrue(succ)
  Check.assertEquals(auth.deploymentId, depl.id)
  Check.assertEquals(auth.systemId, depl.systemId)
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
  succ, err = self.rsMgt.__try:removeAuthorization(depl.id)
  Check.assertTrue(succ)
end

function Test4:testGrantRevokeGetAuthorization()
  local succ, err, auth
  local depl = self.deployments[1]
  for _, iface in ipairs(self.ifaces) do
    succ, err = self.rsMgt.__try:grant(depl.id, iface, true)
    Check.assertTrue(succ)
  end
  --
  for _, iface in ipairs(self.ifaces) do
    succ, err = self.rsMgt.__try:revoke(depl.id, iface)
    Check.assertTrue(succ)
  end
  --
  succ, err = self.rsMgt.__try:getAuthorization(depl.id)
  Check.assertFalse(succ)
  Check.assertEquals("IDL:openbusidl/rs/AuthorizationNonExistent:1.0", err[1])
end

function Test4:testGetAuthorizations()
  local succ, err, auths
  local tmp = {}
  for _, depl in ipairs(self.deployments) do
    for _, iface in ipairs(self.ifaces) do
      succ, err = self.rsMgt.__try:grant(depl.id, iface, true)
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
  succ, auths = self.rsMgt.__try:getAuthorizations()
  Check.assertTrue(succ)
  --
  -- Pode haver mais autorizações do que as cadastradas,
  -- ter cuidado na ordem da iteração.
  --
  local found = false
  for id, ifaces in ipairs(tmp) do
    for _, auth in ipairs(auths) do
      if id == auth.deploymentId then
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
    succ, err = self.rsMgt.__try:removeAuthorization(depl.id)
    Check.assertTrue(succ)
    succ, err = self.rsMgt.__try:getAuthorization(depl.id)
    Check.assertFalse(succ)
    Check.assertEquals("IDL:openbusidl/rs/AuthorizationNonExistent:1.0", err[1])
  end
end

function Test4:testGetAuthorizationsBySystemId()
  local succ, err, auths
  local tmp = {}
  for i, depl in ipairs(self.deployments) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt.__try:grant(depl.id, iface, true)
    Check.assertTrue(succ)
    tmp[depl.id] = iface
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, auths = self.rsMgt.__try:getAuthorizationsBySystemId(depl.systemId)
    local auth = auths[1]
    Check.assertTrue(succ)
    Check.assertTrue(#auths == 1)
    Check.assertEquals(auth.deploymentId, depl.id)
    Check.assertEquals(auth.systemId, depl.systemId)
    Check.assertTrue(#auth.authorized == 1)
    Check.assertEquals(auth.authorized[1], tmp[depl.id])
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.rsMgt.__try:removeAuthorization(depl.id)
    Check.assertTrue(succ)
  end
end

function Test4:testGetAuthorizationsByInterfaceId()
  local succ, err, auths
  local tmp = {}
  for i, depl in ipairs(self.deployments) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt.__try:grant(depl.id, iface, true)
    Check.assertTrue(succ)
    tmp[depl.id] = iface
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, auths = self.rsMgt.__try:getAuthorizationsByInterfaceId({
      tmp[depl.id]
    })
    local auth = auths[1]
    Check.assertTrue(succ)
    Check.assertTrue(#auths == 1)
    Check.assertEquals(auth.deploymentId, depl.id)
    Check.assertEquals(auth.systemId, depl.systemId)
    Check.assertTrue(#auth.authorized == 1)
    Check.assertEquals(auth.authorized[1], tmp[depl.id])
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.rsMgt.__try:removeAuthorization(depl.id)
    Check.assertTrue(succ)
  end
end

function Test4:testGetAuthorizationsByInterfaceIdCommon()
  local succ, err, auths
  local ibase = "IDL:test/management/do/not/use/this/for/real:1.0"
  local tmp = {}
  for i, depl in ipairs(self.deployments) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt.__try:grant(depl.id, iface, true)
    Check.assertTrue(succ)
    succ, err = self.rsMgt.__try:grant(depl.id, ibase, false)
    Check.assertTrue(succ)
    tmp[depl.id] = iface
  end
  --
  succ, auths = self.rsMgt.__try:getAuthorizationsByInterfaceId({ibase})
  Check.assertTrue(succ)
  Check.assertTrue(#auths == #self.deployments)
  --
  for _, depl in ipairs(self.deployments) do
    succ, err = self.rsMgt.__try:removeAuthorization(depl.id)
    Check.assertTrue(succ)
  end
end

function Test4:testGetAuthorizationsByInterfaceIdMulti()
  local succ, err, auths
  local ibase = "IDL:test/management/do/not/use/this/for/real:1.0"
  local tmp = {}
  for i, depl in ipairs(self.deployments) do
    local iface = self.ifaces[i]
    succ, err = self.rsMgt.__try:grant(depl.id, iface, true)
    Check.assertTrue(succ)
    succ, err = self.rsMgt.__try:grant(depl.id, ibase, false)
    Check.assertTrue(succ)
    tmp[depl.id] = iface
  end
  --
  for _, depl in ipairs(self.deployments) do
    succ, auths = self.rsMgt.__try:getAuthorizationsByInterfaceId({
      ibase,
      tmp[depl.id]
    })
    local auth = auths[1]
    Check.assertTrue(succ)
    Check.assertTrue(#auths == 1)
    Check.assertEquals(auth.deploymentId, depl.id)
    Check.assertEquals(auth.systemId, depl.systemId)
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
    succ, err = self.rsMgt.__try:removeAuthorization(depl.id)
    Check.assertTrue(succ)
  end
end