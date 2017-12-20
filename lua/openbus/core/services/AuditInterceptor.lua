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
local AuditAgent = require "openbus.core.audit.Agent"
local AuditInterceptor = class({}, BusInterceptor)

local Default = {}

function AuditInterceptor:__init()
  local config = class(self.config or {}, Default)
  assert(config.httpendpoint, "missing audit agent httpendpoint")

  self.config = config
  self.auditevents = setmetatable({},{__mode = "k"})
  self.agent = AuditAgent{
    config = {
      -- see all configuration options on Audit Agent source code
      concurrency = config.concurrency,
      retrytimeout = config.retrytimeout,
      discardonexit = config.discardonexit,
      fifolimit = config.fifolimit,
      httpproxy = config.httpproxy,
      httpendpoint = config.httpendpoint,
      httpcredentials = config.httpcredentials,
    }
  }
  AuditEvent.config = {
    -- see all configuration options on Audit Event source code
    application = config.application,
    instance = config.instance,
  }
end

function AuditInterceptor:receiverequest(request, ...)
  BusInterceptor.receiverequest(self, request, ...)
  local chain = self:getCallerChain()
  local event = AuditEvent()
  event:incoming(request, chain)
  self.auditevents[running()] = event
end

function AuditInterceptor:sendreply(request)
  BusInterceptor.sendreply(self, request)
  local thread = running()
  local event = self.auditevents[thread]
  if event ~= nil then
    event:outgoing(request)
    self.agent:publish(event)
    self.auditevents[thread] = nil
  end
end

function AuditInterceptor:shutdown()
  self.agent:shutdown()
end

return AuditInterceptor
