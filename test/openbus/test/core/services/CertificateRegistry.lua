local io = require "io"

local cached = require "loop.cached"
local checks = require "loop.test.checks"
local Fixture = require "loop.test.Fixture"
local Suite = require "loop.test.Suite"

local idl = require "openbus.core.idl"
local UnauthorizedOperation = idl.types.services.UnauthorizedOperation
local MissingCertificate = idl.types.services.access_control.MissingCertificate
local admidl = require "openbus.core.admin.idl"
local CertificateRegistry = admidl.types.services.access_control.admin.v1_0.CertificateRegistry
local InvalidCertificate = admidl.types.services.access_control.admin.v1_0.InvalidCertificate

-- Configurações --------------------------------------------------------------

require "openbus.test.core.services.utils"

local FakeEntityName = "FakeEntityName"

-- Funções auxiliares ---------------------------------------------------------

local SomeCertificate do
  local file = assert(io.open(syscrt, "rb"))
  SomeCertificate = file:read("*a")
  file:close()
end

local CertificatesFixture = cached.class({}, IdentityFixture)

function CertificatesFixture:setup(openbus)
  IdentityFixture.setup(self, openbus)
  local certificates = self.certificates
  if certificates == nil then
    local conn = openbus.context:getCurrentConnection()
    local facet = conn.bus:getFacetByName("CertificateRegistry")
    certificates = openbus.orb:narrow(facet, CertificateRegistry)
    self.certificates = certificates
  end
  local unregistered = self.unregistered
  if unregistered ~= nil then
    local context = openbus.context
    if self.identity ~= "admin" then
      local admin = self:newConn("admin")
      context:setCurrentConnection(admin)
      self.admin = admin
    end
    for _, entity in ipairs(unregistered) do
      local ok, err = pcall(certificates.getCertificate, certificates, entity)
      checks.assert(ok, checks.equal(false))
      checks.assert(err._repid, checks.equal(MissingCertificate))
    end
    context:setCurrentConnection(nil)
  end
end

function CertificatesFixture:teardown(openbus)
  local unregistered = self.unregistered
  if unregistered ~= nil then
    if self.identity ~= "admin" then
      openbus.context:setCurrentConnection(self.admin)
    end
    for _, entity in ipairs(unregistered) do
      self.certificates:removeCertificate(entity)
    end
  end
  return IdentityFixture.teardown(self, openbus)
end

-- Testes do CertificateRegistry ----------------------------------------------

return OpenBusFixture{
  idlloaders = { admidl.loadto },
  Suite{
    --------------------------------
    -- Caso de teste "NO PERMISSION"
    --------------------------------
    AsUser = CertificatesFixture{
      identity = "user",
      unregistered = { FakeEntityName },
      tests = Suite(makeSimpleTests{
        certificates = {
          registerCertificate = {
            Unauthorized = {
              params = { FakeEntityName, SomeCertificate },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          getCertificate = {
            Unauthorized = {
              params = { FakeEntityName },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          getEntitiesWithCertificate = {
            Unauthorized = {
              params = { FakeEntityName },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
          removeCertificate = {
            Unauthorized = {
              params = { FakeEntityName },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
        },
      }),
    },
    AsAdmin = CertificatesFixture{
      identity = "admin",
      unregistered = {
        FakeEntityName,
        FakeEntityName.."-1",
        FakeEntityName.."-2",
        FakeEntityName.."-3",
      },
      tests = Suite(makeSimpleTests{
        -------------------------------------
        -- Caso de teste "INVALID PARAMETERS"
        -------------------------------------
        certificates = {
          registerCertificate = {
            Empty = {
              params = { FakeEntityName, "" },
              except = checks.like{_repid=InvalidCertificate},
            },
            Invalid = {
              params = { FakeEntityName, "\n--CORRUPTED!--\n"..SomeCertificate },
              except = checks.like{_repid=InvalidCertificate},
            },
          },
          getCertificate = {
            Missing = {
              params = { FakeEntityName },
              except = checks.like{
                _repid = MissingCertificate,
                entity = FakeEntityName,
              },
            },
          },
          removeCertificate = {
            Missing = {
              params = { FakeEntityName },
              result = { checks.equal(false) },
            },
          },
        },
        -------------------------
        -- Caso de teste "PADRÃO"
        -------------------------
        RegisterRemoveCertificate = function (fixture)
          local certificates = fixture.certificates
          certificates:registerCertificate(FakeEntityName, SomeCertificate)
          local removed = certificates:removeCertificate(FakeEntityName)
          checks.assert(removed, checks.equal(true))
        end,
        RegisterGetRemoveCertificate = function (fixture)
          local certificates = fixture.certificates
          certificates:registerCertificate(FakeEntityName, SomeCertificate)
          local certificate = certificates:getCertificate(FakeEntityName)
          checks.assert(certificate, checks.equal(SomeCertificate))
          local removed = certificates:removeCertificate(FakeEntityName)
          checks.assert(removed, checks.equal(true))
        end,
        RegisterCertificateTwice = function (fixture)
          local certificates = fixture.certificates
          certificates:registerCertificate(FakeEntityName, SomeCertificate)
          certificates:registerCertificate(FakeEntityName, SomeCertificate)
          local removed = certificates:removeCertificate(FakeEntityName)
          checks.assert(removed, checks.equal(true))
          removed = certificates:removeCertificate(FakeEntityName)
          checks.assert(removed, checks.equal(false))
        end,
        GetListWithManyEntitiesWithCertificate = function (fixture)
          local certificates = fixture.certificates
          -- get entities with previously registered certificates
          local previous = {}
          local prevcount
          for index, entity in ipairs(certificates:getEntitiesWithCertificate()) do
            previous[entity] = true
            prevcount = index
          end
          -- register some new certificates
          local count = 3
          local expected = {}
          for i = 1, count do
            local entity = FakeEntityName.."-"..i
            expected[entity] = true
            certificates:registerCertificate(entity, SomeCertificate)
          end
          -- check the new list inclue the new entities with registered certificates
          local list = certificates:getEntitiesWithCertificate()
          checks.assert(#list, checks.equal(prevcount+count))
          for _, entity in ipairs(list) do
            if previous[entity] == nil then
              checks.assert(expected[entity], checks.equal(true))
              expected[entity] = nil
              local removed = certificates:removeCertificate(entity)
              checks.assert(removed, checks.equal(true))
            end
          end
        end,
      }),
    },
  },
}
