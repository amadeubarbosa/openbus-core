
local oil = require"oil"
local oop = require "loop.base"
local Timer = require "loop.thread.Timer"
local log = require "openbus.common.Log"

local tostring = tostring

---
--Objeto que é responsável por renovar o lease junto a um Provider tolerante a falhas.
---
local LeaseRenewer = require "openbus.common.LeaseRenewer"

module "openbus.common.FTLeaseRenewer"

oop.class(_M, LeaseRenewer)

function __init(self, lease, credential, leaseProvider, leaseExpiredCallback)
  local obj = 
    LeaseRenewer.__init(self, lease, credential, leaseProvider, leaseExpiredCallback)
  return obj
end

---
--Obtém o provedor do lease.
--
--@return O provedor do lease.
---
function getProvider(self)
  return self.provider
end

---
--Inicia a execução do renovador de lease.
---
function startRenew(self)
  if not self.timer then
    -- Aloca uma "thread" para a renovação do lease
    local timer = Timer{
      scheduler = oil.tasks,
      rate = self.lease,
    }
    function timer.action(timer)
      local provider = self:getProvider()
      local granted, newlease  = provider:renewLease(self.credential)

      if not granted then
        log:lease("Lease não renovado.")
        timer:disable()
        if self.leaseExpiredCallback then
          self.leaseExpiredCallback()
        end
        return
      end
      if timer.rate ~= newlease then
        timer.rate = newlease
        self:setLease(newlease)
      end
    end
    self.timer = timer
  end
  self.timer.rate = self.lease
  self.timer:enable()
end
