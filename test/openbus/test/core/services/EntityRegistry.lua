local cached = require "loop.cached"
local checks = require "loop.test.checks"
local Fixture = require "loop.test.Fixture"
local Suite = require "loop.test.Suite"

local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local openbus = require "openbus"
local idl = require "openbus.core.idl"
local UnauthorizedOperation = idl.types.services.UnauthorizedOperation
local admidl = require "openbus.core.admin.idl"
local offadm = admidl.types.services.offer_registry.admin.v1_0
local AuthorizationInUse = offadm.AuthorizationInUse
local EntityAlreadyRegistered = offadm.EntityAlreadyRegistered
local EntityCategory = offadm.EntityCategory
local EntityCategoryAlreadyExists = offadm.EntityCategoryAlreadyExists
local EntityCategoryInUse = offadm.EntityCategoryInUse
local EntityRegistry = offadm.EntityRegistry
local InvalidInterface = offadm.InvalidInterface
local RegisteredEntity = offadm.RegisteredEntity

-- Configurações --------------------------------------------------------------

require "openbus.test.core.services.utils"

local CategoryId = category
local CategoryName = "OpenBus 2.0 Test Entities"
local EntityId = system
local EntityName = "OpenBus 2.0 Test System"
local GrantedInterface = "IDL:Ping:1.0"
local SomeInterface = "IDL:Hello:1.0"
local FakeCategory = "Test Category (should not remain after the tests)"
local FakeEntity = "Test Entity Description (should not remain after the tests)"
local SomeCategoryName = "Test Category Description (should not remain after the tests)"
local SomeEntityName = "Test Entity Description (should not remain after the tests)"

-- Funções auxiliares ---------------------------------------------------------

local likeCategoryDesc = checks.like{ id=CategoryId, name=CategoryName }

local function isCategory(value)
  if value:_is_a(EntityCategory) then
    return likeCategoryDesc(value:describe())
  end
  return false, "invalid EntityCategory"
end

local function isCategoryDesc(value)
  local ok, err = likeCategoryDesc(value)
  if ok then
    ok, err = isCategory(value.ref)
  end
  return ok, err
end

local function containsCategoryDesc(categories)
  local found = false
  for _, category in ipairs(categories) do
    if category.id == CategoryId then
      checks.assert(category, isCategoryDesc)
      found = true
    else
      checks.assert(category.id, checks.type("string", "invalid category.id in sequence"))
      checks.assert(category.name, checks.type("string", "invalid category.name in sequence"))
      checks.assert(category.ref:_is_a(EntityCategory), checks.equal(true, "invalid category.ref in sequence"))
    end
  end
  if not found then
    return false, checks.viewer:tostring(categories).." does not contain the expected category"
  end
  return true
end

local likeEntityDesc = checks.like{ id=EntityId, name=EntityName }

local function isEntity(value)
  if value:_is_a(RegisteredEntity) then
    return likeEntityDesc(value:describe())
  end
  return false, "invalid RegisteredEntity"
end

local function isEntityDesc(value)
  local ok, err = likeEntityDesc(value)
  if ok then
    ok, err = isCategory(value.category)
    if ok then
      ok, err = isEntity(value.ref)
    end
  end
  return ok, err
end

local function containsEntityDesc(entities)
  local found = false
  for _, entity in ipairs(entities) do
    if entity.id == EntityId then
      checks.assert(entity, isEntityDesc)
      found = true
    else
      checks.assert(entity.id, checks.type("string", "invalid entity.id in sequence"))
      checks.assert(entity.name, checks.type("string", "invalid entity.name in sequence"))
      checks.assert(entity.category:_is_a(EntityCategory), checks.equal(true, "invalid entity.category in sequence"))
      checks.assert(entity.ref:_is_a(RegisteredEntity), checks.equal(true, "invalid entity.ref in sequence"))
    end
  end
  if not found then
    return false, checks.viewer:tostring(entities).." does not contain the expected entity"
  end
  return true
end

local EntitiesFixture = cached.class({}, IdentityFixture)

function EntitiesFixture:setup(openbus)
  IdentityFixture.setup(self, openbus)
  local entities = self.entities
  if entities == nil then
    local conn = openbus.context:getCurrentConnection()
    local facet = conn.bus:getFacetByName("EntityRegistry")
    entities = openbus.orb:narrow(facet, EntityRegistry)
    self.entities = entities
  end
  local category = self.category
  if category == nil then
    category = entities:getEntityCategory(CategoryId)
    checks.assert(category, checks.NOT(checks.equal(nil)))
    self.category = category
  end
  local entity = self.entity
  if entity == nil then
    entity = entities:getEntity(EntityId)
    checks.assert(entity, checks.NOT(checks.equal(nil)))
    self.entity = entity
  end
  local unregistered = self.unregistered
  if unregistered ~= nil then
    local categorylist = unregistered.category
    if categorylist ~= nil then
      for _, category in ipairs(categorylist) do
        checks.assert(entities:getEntityCategory(category), checks.equal(nil))
      end
    end
    local entitylist = unregistered.entities
    if entitylist ~= nil then
      for _, entity in ipairs(self.unregistered.entities) do
        checks.assert(entities:getEntity(entity), checks.equal(nil))
      end
    end
  end
end

function EntitiesFixture:teardown(openbus)
  local unregistered = self.unregistered
  if unregistered ~= nil then
    if self.identity ~= "admin" then
      openbus.context:setCurrentConnection(self:newConn("admin"))
    end
    local entities = self.entities
    local entitylist = unregistered.entities
    if entitylist ~= nil then
      for _, entity in ipairs(entitylist) do
        local ref = entities:getEntity(entity)
        if ref ~= nil then
          ref:remove()
        end
      end
    end
    local categorylist = unregistered.category
    if categorylist ~= nil then
      for _, category in ipairs(categorylist) do
        local ref = entities:getEntityCategory(category)
        if ref ~= nil then
          ref:removeAll()
        end
      end
    end
  end
  return IdentityFixture.teardown(self, openbus)
end

-- Testes do EntityRegistry ----------------------------------------------

return OpenBusFixture{
  idlloaders = { admidl.loadto },
  Suite{
    --------------------------------
    -- Caso de teste "NO PERMISSION"
    --------------------------------
    AsUser = EntitiesFixture{
      identity = "user",
      unregistered = {
        categories = { FakeCategory },
        entities = { FakeEntity },
      },
      tests = makeSimpleTests{
        entities = {
          createEntityCategory = {
            Unauthorized = {
              params = { FakeCategory, SomeCategoryName },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          getEntityCategories = {
            Call = {
              params = {},
              result = { containsCategoryDesc },
            },
          },
          getEntityCategory = {
            Call = {
              params = { CategoryId },
              result = { isCategory },
            },
          },
          getEntities = {
            Call = {
              params = {},
              result = { containsEntityDesc },
            },
          },
          getEntity = {
            Call = {
              params = { EntityId },
              result = { isEntity },
            },
          },
          getAuthorizedEntities = {
            Call = {
              params = {},
              result = { containsEntityDesc },
            },
          },
          getEntitiesByAuthorizedInterfaces = {
            Call = {
              params = { {GrantedInterface} },
              result = { containsEntityDesc },
            },
          },
        },
        category = {
          _get_id = {
            Call = {
              params = {},
              result = { checks.equal(CategoryId) },
            },
          },
          _get_name = {
            Call = {
              params = {},
              result = { checks.equal(CategoryName) },
            },
          },
          describe = {
            Call = {
              params = {},
              result = { isCategoryDesc },
            },
          },
          setName = {
            Unauthorized = {
              params = { CategoryName },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          remove = {
            Unauthorized = {
              params = {},
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          removeAll = {
            Unauthorized = {
              params = {},
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          registerEntity = {
            Unauthorized = {
              params = { FakeEntity, SomeEntityName },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          getEntities = {
            Call = {
              params = {},
              result = { containsEntityDesc },
            },
          },
        },
        entity = {
          _get_category = {
            Call = {
              params = {},
              result = { isCategory },
            },
          },
          _get_id = {
            Call = {
              params = {},
              result = { checks.equal(EntityId) },
            },
          },
          _get_name = {
            Call = {
              params = {},
              result = { checks.equal(EntityName) },
            },
          },
          describe = {
            Call = {
              params = {},
              result = { isEntityDesc },
            },
          },
          setName = {
            Unauthorized = {
              params = { EntityName },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          remove = {
            Unauthorized = {
              params = {},
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          grantInterface = {
            Unauthorized = {
              params = { SomeInterface },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          revokeInterface = {
            Unauthorized = {
              params = { GrantedInterface },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          getGrantedInterfaces = {
            Unauthorized = {
              params = {},
              result = { checks.like{GrantedInterface} },
            },
          },
        },
      },
    },
    AsAdmin = EntitiesFixture{
      identity = "admin",
      unregistered = {
        categories = { FakeCategory },
        entities = { FakeEntity },
      },
      tests = makeSimpleTests{
        entities = {
          createEntityCategory = {
            EmptyId = {
              params = { "", SomeCategoryName },
              except = checks.like{_repid=sysex.BAD_PARAM, completed="COMPLETED_NO", minor=0},
            },
            Existing = {
              params = { CategoryId, SomeCategoryName },
              except = checks.like{
                _repid = EntityCategoryAlreadyExists,
                existing = {
                  id = CategoryId,
                  name = CategoryName,
                },
              },
            },
          },
        },
        category = {
          setName = {
            Call = {
              params = { CategoryName },
              result = {},
            },
          },
          registerEntity = {
            EmptyId = {
              params = { "", SomeEntityName },
              except = checks.like{_repid=sysex.BAD_PARAM, completed="COMPLETED_NO", minor=0},
            },
            Existing = {
              params = { EntityId, SomeEntityName },
              except = checks.like{
                _repid = EntityAlreadyRegistered,
                existing = {
                  id = EntityId,
                  name = EntityName,
                },
              },
            },
          },
          remove = {
            InUse = {
              params = {},
              except = function (except)
                checks.assert(except._repid, checks.equal(EntityCategoryInUse))
                checks.assert(except.entities, containsEntityDesc)
                return true
              end,
            },
          },
        },
        entity = {
          setName = {
            Call = {
              params = { EntityName },
              result = {},
            },
          },
          grantInterface = {
            Invalid = {
              params = { SomeInterface },
              except = checks.like{_repid=InvalidInterface, ifaceId=SomeInterface},
            },
          },
        },
        RegisterEntityInTwoCategories = function (fixture)
          local entities = fixture.entities
          local category = entities:createEntityCategory(FakeCategory, SomeCategoryName)
          local ok, err = pcall(category.registerEntity, category, EntityId, EntityName)
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{_repid=EntityAlreadyRegistered})
          checks.assert(err.existing, isEntityDesc)
          category:remove()
        end,
        RegisterEntityAndGrantInterface = function (fixture)
          local category = fixture.category
          local entity = category:registerEntity(FakeEntity, SomeEntityName)
          entity:grantInterface(GrantedInterface)
          checks.assert(entity:getGrantedInterfaces(), checks.like{GrantedInterface})

          local entities = fixture.entities
          local authorized = entities:getAuthorizedEntities()
          checks.assert(authorized, checks.contains{
            id = FakeEntity,
            name = SomeEntityName,
          })
          authorized = entities:getEntitiesByAuthorizedInterfaces({GrantedInterface})
          checks.assert(authorized, checks.contains{
            id = FakeEntity,
            name = SomeEntityName,
          })

          entity:remove()

          authorized = entities:getAuthorizedEntities()
          checks.assert(authorized, checks.NOT(checks.contains{
            id = FakeEntity,
            name = SomeEntityName,
          }))
          authorized = entities:getEntitiesByAuthorizedInterfaces({GrantedInterface})
          checks.assert(authorized, checks.NOT(checks.contains{
            id = FakeEntity,
            name = SomeEntityName,
          }))
        end,
        RevokeAuhtorizationInUse = function (fixture, openbus)
          -- create component
          local ComponentContext = require "scs.core.ComponentContext"
          local orb = openbus.orb
          orb:loadidl("interface Ping { boolean ping(); };")
          local component = ComponentContext(orb, {
            name = "Ping Component",
            major_version = 1,
            minor_version = 2,
            patch_version = 3,
            platform_spec = "none",
          })
          component:addFacet("ping", GrantedInterface, {
            ping = function ()
              component.count = component.count+1
              return true
            end,
          })
          -- register service offer
          local context = openbus.context
          local system = fixture:newConn("system")
          context:setCurrentConnection(system)
          local offers = openbus.context:getOfferRegistry()
          local props = {{name="some.property",value="some value"}}
          local offer = offers:registerService(component.IComponent, props)
          context:setCurrentConnection(nil)
          -- try to revoke authorization in use
          local entities = fixture.entities
          local entity = entities:getEntity(EntityId)
          local ok, err = pcall(entity.revokeInterface, entity, GrantedInterface)
          checks.assert(ok, checks.equal(false))
          checks.assert(err._repid, checks.equal(AuthorizationInUse))
          local offerdesc = err.offers[1]
          checks.assert(offerdesc.service_ref, checks.equal(component.IComponent.__servant))
          checks.assert(offerdesc.properties, checks.contains(props[1]))
        end
      },
    },
  },
}
