-- Audit Inteceptor to publish data in a HTTP REST service
-- 
-- FIXME: 
--   [x] audit http authentication
--   [ ] audit interceptor should be inject in busservices
--   [x] audit event mapping should be configurable (request, caller) -> (audit event class)
--   [ ] should serialize on disk/sqlite when shutting down ?
--   [i] should serialize under cache overflow ? (i: FIFO now has limits)
--   [ ] should log entire event collected or just an ID ?
--   [ ] should log in a new 'audit' level ?

local _G = require "_G"
local setmetatable = _G.setmetatable
local assert = _G.assert

local coroutine = require "coroutine"
local running = coroutine.running

local oo = require "openbus.util.oo"
local class = oo.class
local log = require "openbus.util.logger"
local msg = require "openbus.core.messages"

local access = require "openbus.core.services.Access"
local BusInterceptor = access.Interceptor

local AuditEvent = require "openbus.core.audit.Event"
local AuditInterceptor = class({}, BusInterceptor)

-- Optional fields that will be used at runtime:
--
--   eventconfig : table containing event configuration
--    auditagent : the agent instance itself
--
function AuditInterceptor:__init()
  self.auditagent = self.auditagent or false
  self.auditevents = setmetatable({},{__mode = "k"})
end

function AuditInterceptor:receiverequest(request, ...)
  BusInterceptor.receiverequest(self, request, ...)
  if self.auditagent then
    local eventconfig = self.eventconfig
    local chain = self:getCallerChain()
    local event = AuditEvent{ config = eventconfig }
    event:incoming(request, chain)
    self.auditevents[running()] = event
  end
end

function AuditInterceptor:sendreply(request)
  BusInterceptor.sendreply(self, request)
  if self.auditagent then
    local thread = running()
    local event = self.auditevents[thread]
    if event ~= nil then
      event:outgoing(request)
      self.auditagent:publish(event)
      self.auditevents[thread] = nil
    end
  end
end

return AuditInterceptor
