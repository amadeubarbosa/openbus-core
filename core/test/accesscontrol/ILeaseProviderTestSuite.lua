--
-- Suite de Testes da interface ILeaseProvider
--
-- $Id$
--
require "oil"
local orb = oil.orb
local Utils = require "openbus.util.Utils"
local Check = require "latt.Check"

local beforeTestCase = dofile("accesscontrol/beforeTestCase.lua")
local beforeEachTest = dofile("accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile("accesscontrol/afterEachTest.lua")
local afterTestCase = dofile("accesscontrol/afterTestCase.lua")

--------------------------------------------------------------------------------

Suite = {
  Test1 = {-- testes com beforeTestCase, beforeEachTest, afterEachTest e afterTestCase
    beforeTestCase = function(self)
      beforeTestCase(self)
      -- recupera a faceta ILeaseProvider
      local facet = self.acsComp:getFacet(Utils.LEASE_PROVIDER_INTERFACE)
      self.leaseProvider = orb:narrow(facet,
          Utils.LEASE_PROVIDER_INTERFACE)
    end,

    afterTestCase = afterTestCase,

    beforeEachTest = beforeEachTest,

    afterEachTest = afterEachTest,

    testRenewLease = function(self)
      local status, time = self.leaseProvider:renewLease(self.credential)
      Check.assertTrue(status)
      Check.assertNotNil(time)
      Check.assertTrue(time > 0)
      Check.assertTrue(self.leaseProvider:renewLease(self.credential))
    end,

    testRenewLeaseAfterLogout = function(self)
      -- logando outro usuário
      local _, userCredential =
          self.accessControlService:loginByPassword(self.login.user, self.login.password)
      local status, time = self.leaseProvider:renewLease(userCredential)
      Check.assertTrue(status)
      Check.assertTrue(self.accessControlService:logout(userCredential))
      local status, time2 = self.leaseProvider:renewLease(userCredential)
      Check.assertFalse(status)
      Check.assertTrue(type(time2) == "number")
      Check.assertNotEquals(time, time2)
    end,

    testRenewLeaseInvalidCredential = function(self)
      -- credencial inválida.
      local invalidCredential = {}
      invalidCredential.identifier = "unknown"
      invalidCredential.owner = "unknown"
      invalidCredential.delegate = "false"
      Check.assertFalse(self.leaseProvider:renewLease(invalidCredential))
    end,
  }
}
