local cached = require "loop.cached"
local checks = require "loop.test.checks"
local Fixture = require "loop.test.Fixture"
local Suite = require "loop.test.Suite"

local openbus = require "openbus"
local sleep = openbus.sleep

local idl = require "openbus.core.idl"
local UnauthorizedOperation = idl.types.services.UnauthorizedOperation
local libidl = require "openbus.idl"
local InvalidLoginProcess = libidl.types.InvalidLoginProcess
local oldidl = require "openbus.core.legacy.idl"
local LegacyUnauthorizedOperation = oldidl.types.v2_0.services.UnauthorizedOperation
local LegacyAccessControlType = oldidl.types.v2_0.services.access_control.AccessControl
local LegacyConverterType = oldidl.types.v2_1.services.legacy_support.LegacyConverter
local InvalidExportedData = oldidl.types.v2_1.services.legacy_support.InvalidExportedData

-- Configurações --------------------------------------------------------------

require "openbus.test.core.services.utils"

local FakeEntityName = "FakeEntityName"

-- Funções auxiliares ---------------------------------------------------------

local LegacySupportFixture = cached.class({}, IdentityFixture)

function LegacySupportFixture:setup(openbus)
  IdentityFixture.setup(self, openbus)
  if self.legacysupport == nil then
    local conn = openbus.context:getCurrentConnection()
    local facet = conn.bus:getFacetByName("LegacySupport")
    self.legacysupport = openbus.orb:narrow(facet, "IDL:scs/core/IComponent:1.0")
    facet = self.legacysupport:getFacetByName("LegacyConverter")
    self.legacyconverter = openbus.orb:narrow(facet, LegacyConverterType)
    facet = self.legacysupport:getFacetByName("AcessControl")
    self.legacyaccesscontrol = openbus.orb:narrow(facet, LegacyAccessControlType)
    self.accesscontrol = conn.AccessControl
  end
end

local function newSyncedTest(action)
  return function (fixture, openbus)
    local sharedauth = openbus.context:getCurrentConnection():startSharedAuth()
    local legacyattempt = fixture.legacyconverter:convertSharedAuth(sharedauth.attempt)
    checks.assert(sharedauth.attempt:_non_existent(), checks.is(false))
    checks.assert(legacyattempt:_non_existent(), checks.is(false))
    action{
      sharedauth = sharedauth,
      legacyattempt = legacyattempt,
      fixture = fixture,
      openbus = openbus,
    }
    checks.assert(sharedauth.attempt:_non_existent(), checks.is(true))
    checks.assert(legacyattempt:_non_existent(), checks.is(true))
    local conn = fixture:newConn()
    local ok, except = pcall(conn.loginBySharedAuth, conn, sharedauth)
    checks.assert(ok, checks.is(false))
    checks.assert(except, checks.like{ _repid = InvalidLoginProcess })
  end
end

-- Testes do CertificateRegistry ----------------------------------------------

return OpenBusFixture{
  Suite{
    AsUser = LegacySupportFixture{
      identity = "user",
      tests = Suite(makeSimpleTests{
        legacyconverter = {
          convertSharedAuth = {
            CancelledAttempt = {
              params = {
                function (fixture, openbus)
                  local sharedauth = openbus.context:getCurrentConnection():startSharedAuth()
                  sharedauth:cancel()
                  return sharedauth.attempt
                end
              },
              except = checks.like{_repid=InvalidExportedData},
            },
            AttemptFromOtherLogin = {
              params = {
                function (fixture, openbus)
                  return fixture:newConn("user"):startSharedAuth().attempt
                end
              },
              except = checks.like{_repid=UnauthorizedOperation},
            },
            AttemptFromOtherEntity = {
              params = {
                function (fixture, openbus)
                  return fixture:newConn("system"):startSharedAuth().attempt
                end
              },
              except = checks.like{_repid=UnauthorizedOperation},
            },
          },
        },
        SyncedUsedSharedAuth = newSyncedTest(function (vars)
          vars.fixture:newConn():loginBySharedAuth(vars.sharedauth)
        end),
        SyncedCancelledSharedAuth = newSyncedTest(function (vars)
          vars.sharedauth:cancel()
        end),
        SyncedLegacyCancelledSharedAuth = newSyncedTest(function (vars)
          vars.legacyattempt:cancel()
        end),
        SyncedExpirationSharedAuth = newSyncedTest(function (vars)
          sleep(2*leasetime)
        end),
      }),
    },
  },
}
