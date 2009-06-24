--
-- Testes unitários do arquivo LeaseExpiredCallback.lua
--
-- $Id: testLeaseExpiredCallback.lua $
--
local LeaseExpiredCallback = require "openbus.lease.LeaseExpiredCallback"
local Check = require "latt.Check"

count = 0
count2 = 0

Suite = {
  Test1 = {
    beforeTestCase = function(self)
    end,
    testCallbacks = function(self)
      local lec = LeaseExpiredCallback()
      local lec2 = LeaseExpiredCallback()
      local function testCB() count = count + 1 end
      local function testCB2() count = count + 1; count2 = count2 + 1 end 

      Check.assertTrue(lec:addLeaseExpiredCallback(testCB))
      Check.assertTrue(lec:addLeaseExpiredCallback(testCB2))
      Check.assertTrue(lec2:addLeaseExpiredCallback(testCB))

      lec:expired()
      Check.assertEquals(count, 2)
      Check.assertEquals(count2, 1)
      lec2:expired()
      Check.assertEquals(count, 3)

      Check.assertTrue(lec:removeLeaseExpiredCallback(testCB))
      Check.assertTrue(lec:removeLeaseExpiredCallback(testCB2))
      Check.assertTrue(lec2:removeLeaseExpiredCallback(testCB))
    end,
 }
}
