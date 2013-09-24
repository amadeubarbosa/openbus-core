local _G = require "_G"
local pcall = _G.pcall

local io = require "io"

local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local openbus = require "openbus"
local idl = require "openbus.core.idl"
local UnauthorizedOperation = idl.types.services.UnauthorizedOperation
local admidl = require "openbus.core.admin.idl"
local offadm = admidl.types.services.offer_registry.admin.v1_0
local EntityCategoryAlreadyExists = offadm.EntityCategoryAlreadyExists
local EntityAlreadyRegistered = offadm.EntityAlreadyRegistered
local EntityCategoryInUse = offadm.EntityCategoryInUse
local InvalidInterface = offadm.InvalidInterface

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

-- Inicialização --------------------------------------------------------------
local orb = openbus.initORB()
local OpenBusContext = orb.OpenBusContext
do
  admidl.loadto(orb)
  local CoreServices = {
    InterfaceRegistry = offadm,
    EntityRegistry = offadm,
  }
  for name, idlmod in pairs(CoreServices) do
    OpenBusContext["get"..name] = function (self)
      local conn = self:getCurrentConnection()
      if conn == nil or conn.login == nil then
        sysexthrow.NO_PERMISSION{
          completed = "COMPLETED_NO",
          minor = loginconst.NoLoginCode,
        }
      end
      local facet = conn.bus:getFacetByName(name)
      return self.orb:narrow(facet, idlmod[name])
    end
  end
end
local connprops = { accesskey = openbus.newKey() }

-- Casos de Teste -------------------------------------------------------------
Suite = {}
Suite.Test1 = {}
Suite.Test2 = {}
Suite.Test3 = {}

-- Aliases
local Case = Suite.Test1
local UpdateCase = Suite.Test2
local NoPermissionCase = Suite.Test3

-- Testes do EntityRegistry ----------------------------------------------

-- -- IDL operations
--  EntityCategory createEntityCategory(in Identifier id, in string name)
--    raises (EntityCategoryAlreadyExists, UnauthorizedOperation);
--  EntityCategoryDescSeq getEntityCategories();
--  EntityCategory getEntityCategory(in Identifier id);
--  RegisteredEntityDescSeq getEntities();
--  RegisteredEntity getEntity(in Identifier id);
--  RegisteredEntityDescSeq getAuthorizedEntities();
--  RegisteredEntityDescSeq getEntitiesByAuthorizedInterfaces(InterfaceIdSeq interfaces);

-- -- IDL operations of EntityCategory
--  readonly attribute Identifier id;
--  readonly attribute string name;
--  EntityCategoryDesc describe();
--  void setName(in string name) raises (UnauthorizedOperation);
--  void remove()
--    raises (EntityCategoryInUse, UnauthorizedOperation);
--  void removeAll() raises (UnauthorizedOperation);
--  RegisteredEntity registerEntity(in Identifier id, in string name)
--    raises (EntityAlreadyRegistered, UnauthorizedOperation);  
--  RegisteredEntityDescSeq getEntities();

-- -- IDL operations of RegisteredEntity
--  readonly attribute EntityCategory category;
--  readonly attribute Identifier id;
--  readonly attribute string name;
--  RegisteredEntityDesc describe();
--  void setName(in string name) raises (UnauthorizedOperation);
--  void remove() raises (UnauthorizedOperation);
--  boolean grantInterface(in InterfaceId ifaceId)
--    raises (InvalidInterface, UnauthorizedOperation);
--  boolean revokeInterface(in InterfaceId ifaceId)
--    raises (InvalidInterface, AuthorizationInUse, UnauthorizedOperation);
--  InterfaceIdSeq getGrantedInterfaces();

--------------------------------
-- Caso de teste "NO PERMISSION"
--------------------------------

function NoPermissionCase.beforeTestCase(self)
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
  
  local adminConn = OpenBusContext:createConnection(host, port, connprops)
  adminConn:loginByPassword(admin, adminPassword)
  OpenBusContext:setCurrentConnection(adminConn)
  local categoryId = "NoPermissionCategory"
  local categoryDesc = "Category to test Unauthorized Operations"
  local category = OpenBusContext:getEntityRegistry():createEntityCategory(categoryId, 
    categoryDesc)
  local entityId = "NoPermissinoEntity"
  local entityDesc = "Entity to test Unauthorized Operations"
  local entity = category:registerEntity(entityId, entityDesc)
  OpenBusContext:setCurrentConnection(nil)
  self.adminConn = adminConn
  self.category = category
  self.categoryId = categoryId
  self.categoryDesc = categoryDesc
  self.entity = entity
  self.entityId = entityId
  self.entityDesc = entityDesc
end

function NoPermissionCase.afterTestCase(self)
  OpenBusContext:setCurrentConnection(self.adminConn)
  self.category:removeAll()
  self.adminConn:logout()
  self.adminConn = nil
  OpenBusContext:setCurrentConnection(nil)
  
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
  self.conn = nil
end

function NoPermissionCase.testEntityRegistryNoPermission(self)
  local entities = OpenBusContext:getEntityRegistry()
  local ok, err = pcall(entities.createEntityCategory, entities, "LoginNotValid",
    "trying to create category with unauthorized login")
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testCategoryNoPermission(self)
  local category = self.category
  local ok, err = pcall(category.setName, category, 
    "should receive unauthorized exception")
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
  ok, err = pcall(category.remove, category)
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
  ok, err = pcall(category.removeAll, category)
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
  ok, err = pcall(category.registerEntity, category, "LoginNotValid",
    "trying to create entity with unauthorized login")
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testEntityNoPermission(self)
  local entity = self.entity
  local ok, err = pcall(entity.setName, entity, 
    "should receive unauthorized exception")
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
  ok, err = pcall(entity.remove, entity)
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
  ok, err = pcall(entity.grantInterface, entity, "IDL:test/Test:1.0")
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
  ok, err = pcall(entity.revokeInterface, entity, "IDL:test/Test:1.0")
  Check.assertTrue(not ok)
  Check.assertEquals(UnauthorizedOperation, err._repid)
end

--------------------------------
-- Caso de teste "EntityRegistry"
--------------------------------

function Case.beforeTestCase(self)
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  local entities = OpenBusContext:getEntityRegistry()
  -- category
  local catId = "UnitTestCategory"
  local catDesc = "Category to use on unit tests"
  local category = entities:createEntityCategory(catId, catDesc)
  -- entity
  local entId = "UnitTestEntity"
  local entDesc = "Entity to use on unit tests"
  local entity = category:registerEntity(entId, entDesc)
  -- saving variables
  self.category = category
  self.catId = catId
  self.catDesc = catDesc
  self.entity = entity
  self.entId = entId
  self.entDesc = entDesc
end

function Case.afterTestCase(self)
  self.category:removeAll()
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
  self.conn = nil
end

function Case.testGetCategory(self)
  local entities = OpenBusContext:getEntityRegistry()
  Check.assertEquals(self.catId, self.category:_get_id())
  Check.assertEquals(self.catDesc, self.category:_get_name())
  local ok, desc = pcall(self.category.describe, self.category)
  Check.assertTrue(ok)
  Check.assertNotNil(desc)
  Check.assertEquals(self.catId, desc.id)
  Check.assertEquals(self.catDesc, desc.name)
  Check.assertNotNil(desc.ref)
  local ok, categories = pcall(entities.getEntityCategories, entities)
  Check.assertTrue(ok)
  Check.assertNotNil(categories)
  Check.assertTrue(#categories > 0)
  local ok, getcat = pcall(entities.getEntityCategory, entities, self.catId)
  Check.assertTrue(ok)
  Check.assertNotNil(getcat)
  Check.assertEquals(self.catId, getcat:_get_id())
  Check.assertEquals(self.catDesc, getcat:_get_name())
end

function Case.testGetEntity(self)
  local entities = OpenBusContext:getEntityRegistry()
  Check.assertEquals(self.entId, self.entity:_get_id())
  Check.assertEquals(self.entDesc, self.entity:_get_name())
  local ok, description = pcall(self.entity.describe, self.entity)
  Check.assertTrue(ok)
  Check.assertNotNil(description)
  Check.assertEquals(self.entId, description.id)
  Check.assertEquals(self.entDesc, description.name)
  Check.assertNotNil(description.ref)
  local entsCat = self.entity:_get_category()
  Check.assertNotNil(entsCat)
  Check.assertEquals(self.catId, entsCat:_get_id())
  Check.assertEquals(self.catDesc, entsCat:_get_name())
  local ok, entSeq = pcall(entities.getEntities, entities)
  Check.assertTrue(ok)
  Check.assertNotNil(entSeq)
  Check.assertTrue(#entSeq > 0)
  local ok, getent = pcall(entities.getEntity, entities, self.entId)
  Check.assertTrue(ok)
  Check.assertEquals(self.entId, getent:_get_id())
  Check.assertEquals(self.entDesc, getent:_get_name())
  entSeq = nil
  ok, entSeq = pcall(self.category.getEntities, self.category)
  Check.assertTrue(ok)
  Check.assertNotNil(entSeq)
  Check.assertEquals(1, #entSeq)
end

function Case.testCreateEmptyIds(self)
  local entities = OpenBusContext:getEntityRegistry()
  local ok, err = pcall(entities.createEntityCategory, entities, "", "")
  Check.assertFalse(ok)
  Check.assertEquals(sysex.BAD_PARAM, err._repid)
  local ok, err = pcall(self.category.registerEntity, self.category, "", "")
  Check.assertFalse(ok)
  Check.assertEquals(sysex.BAD_PARAM, err._repid)
end

function Case.testCreateTwice(self)
  local entities = OpenBusContext:getEntityRegistry()
  local ok, err = pcall(entities.createEntityCategory, entities, 
    self.catId, self.catDesc)
  Check.assertTrue(not ok)
  Check.assertEquals(EntityCategoryAlreadyExists, err._repid)
  ok, err = pcall(self.category.registerEntity, self.category, 
    self.entId, self.entDesc)
  Check.assertTrue(not ok)
  Check.assertEquals(EntityAlreadyRegistered, err._repid)
end

function Case.testRegisterEntityInTwoCategories(self)
  local entities = OpenBusContext:getEntityRegistry()
  local category = entities:createEntityCategory("Fake", "Fake Category")
  ok, err = pcall(category.registerEntity, category, self.entId, self.entDesc)
  Check.assertTrue(not ok)
  Check.assertEquals(EntityAlreadyRegistered, err._repid)
  category:remove()
end

function Case.testCategoryInUse(self)
  local ok, err = pcall(self.category.remove, self.category)
  Check.assertTrue(not ok)
  Check.assertEquals(EntityCategoryInUse, err._repid)
end

function Case.testEntityAuthorization(self)
  local conn = self.conn
  local entities = OpenBusContext:getEntityRegistry()
  local interface = "IDL:test/Test:1.0"
  local ok, err = pcall(self.entity.grantInterface, self.entity, "InvalidInterface")
  Check.assertTrue(not ok)
  Check.assertEquals(InvalidInterface, err._repid)
  local ok, list = pcall(self.entity.getGrantedInterfaces, self.entity)
  Check.assertTrue(ok)
  Check.assertEquals(0, #list)
  OpenBusContext:getInterfaceRegistry():registerInterface(interface)
  local ok, bool = pcall(self.entity.grantInterface, self.entity, interface)
  Check.assertTrue(ok)
  Check.assertTrue(bool)
  ok, bool = pcall(self.entity.grantInterface, self.entity, interface)
  Check.assertTrue(ok)
  Check.assertFalse(bool)
  local ok, list = pcall(self.entity.getGrantedInterfaces, self.entity)
  Check.assertTrue(ok)
  Check.assertEquals(1, #list)
  Check.assertEquals(interface, list[1])
  
  local ok, authorizedList = pcall(entities.getAuthorizedEntities, entities)
  Check.assertTrue(ok)
  Check.assertTrue(#list > 0)
  ok, authorizedList = pcall(entities.getEntitiesByAuthorizedInterfaces,
    entities, {interface})
  Check.assertTrue(ok)
  Check.assertEquals(1, #list)
  local descEntity = authorizedList[1]
  Check.assertEquals(self.entId, descEntity.id)
  Check.assertEquals(self.entDesc, descEntity.name)  
  ok, err = pcall(self.entity.revokeInterface, self.entity, "InvalidInterface")
  Check.assertTrue(not ok)
  Check.assertEquals(InvalidInterface, err._repid)
  ok, bool = pcall(self.entity.revokeInterface, self.entity, interface)
  Check.assertTrue(ok)
  Check.assertTrue(bool)
  OpenBusContext:getInterfaceRegistry():removeInterface(interface)
end

--------------------------------
-- Caso de teste de Atualização
--------------------------------

function UpdateCase.beforeTestCase(self)
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  local entities = OpenBusContext:getEntityRegistry()
  -- category
  local catId = "UnitTestCategory"
  local catDesc = "Category to use on unit tests"
  local category = entities:createEntityCategory(catId, catDesc)
  -- entity
  local entId = "UnitTestEntity"
  local entDesc = "Entity to use on unit tests"
  local entity = category:registerEntity(entId, entDesc)
  -- saving variables
  self.category = category
  self.catId = catId
  self.catDesc = catDesc
  self.entity = entity
  self.entId = entId
  self.entDesc = entDesc
end

function UpdateCase.afterTestCase(self)
  self.entity:remove()
  self.category:remove()
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
  self.conn = nil
end

function UpdateCase.testUpdateCategory(self)
  local newDesc = "new category desc"
  local ok, err = pcall(self.category.setName, self.category, newDesc)
  Check.assertTrue(ok)
  Check.assertEquals(newDesc, self.category:_get_name())
end

function UpdateCase.testUpdateEntity(self)
  local newDesc = "new entity desc"
  local ok, err = pcall(self.entity.setName, self.entity, newDesc)
  Check.assertTrue(ok)
  Check.assertEquals(newDesc, self.entity:_get_name())  
end

  
