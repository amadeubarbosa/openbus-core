local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local pairs = _G.pairs

local array = require "table"
local os = require "os"
local date = os.date
local tmpname = os.tmpname

local thread = require "openbus.util.thread"
local spawn = thread.spawn

local msg = require "openbus.core.messages"

local uuid = require "uuid"
local newid = uuid.new

local coroutine = require "coroutine"
local newthread = coroutine.create

local cothread = require "cothread"
cothread.plugin(require "cothread.plugin.socket")
local time = cothread.now
local running = cothread.running
local schedule = cothread.schedule

local socket = require "cothread.socket"

local log = require "openbus.util.logger"
local oo = require "openbus.util.oo"
local class = oo.class

local access = require "openbus.core.services.Access"
local BusInterceptor = access.Interceptor

local AuditInterceptor = class({}, BusInterceptor)

local default = {
  host = "localhost",
  port = 2088,
  httpendpoint = "localhost:51400",
  httpproxy = nil,
  auditloglevel = 5,
  auditlogfile = "openbus.audit.log",
}

function AuditInterceptor:__init()
  local config = class(self.config or {}, default)
  assert(config.host, "missing audit agent host")
  assert(tonumber(config.port), "missing audit agent port")
  assert(config.httpendpoint, "missing audit agent httpendpoint")

  self.config = config
  self.auditevents = setmetatable({},{__mode = "k"})

  spawn([=[
local _G = require "_G"
local pairs = _G.pairs
local assert = _G.assert

local table = require "table"
local string = require "string"
local coroutine = require "coroutine"
local newthread = coroutine.create
local cothread = require "cothread"
local schedule = cothread.schedule
local unschedule = cothread.unschedule
cothread.plugin(require "cothread.plugin.socket")
local socket = require "cothread.socket"

local oo = require "openbus.util.oo"
local log = require "openbus.util.logger"
local setuplog = require("openbus.util.server").setuplog
local msg = require "openbus.core.messages"

-- lib extension
function string.split(str,ch)
  local pat = string.len(ch) == 1 and "[^"..ch.."]*" or ch
  local tbl={}
  str:gsub(pat,function(x) if x ~= "" then tbl[#tbl+1]=x end end)
  return tbl
end
function coroutine.id()
    return tostring(coroutine.running())
end

-- a minimalist lib for http posting
local http = {
    connect = function(self, config)
        local function urlencode(tbl, resource)
          local server, port, url
          if tbl.proxy ~= nil then
            server = tbl.proxy:split(":")[1]
            port = tonumber(tbl.proxy:split(":")[2])
            url = "http://" .. tbl.host .. (resource or "/")
          else
            server = tbl.host:split(":")[1]
            port = tonumber(tbl.host:split(":")[2]) or 80
            url = resource or "/"
          end
          return url, server, port
        end

        local obj = oo.class({}, self)
        obj.config = assert(config, "missing server configuration")
        obj.tcp = socket.tcp()
        local url, server, port = urlencode(config)
        assert(obj.tcp:connect(server, port))
        obj.server = server
        obj.port = port
        obj.url = url
        return obj
    end,
    close = function(self)
        self.tcp:close()
    end,
    send = function(self, ...)
        return self.tcp:send(...)
    end,
    receive = function(self, ...)
        local response = ""
        while true do
            self.tcp:settimeout(1) -- avoid busy wait
            local data, status = self.tcp:receive(...)
            response = response .. (data or "")
            if status == "closed" then break end
            coroutine.yield("delay", .1)
        end
        local _, _, version, code = string.find(response, "(HTTP/%d*%.%d*) (%d%d%d)")
        return tonumber(code), response, version
    end,
    post = function(self, resource, jsonstr)
      local function table2headers(tbl)
        local headers = ""
        for name, value in pairs(tbl) do
          headers = headers..name..": "..value.."\r\n"
        end
        return headers
      end

      schedule(newthread(function ()
        local headers do
          headers = {}
          headers["Content-Length"] = string.len(jsonstr)
          headers["Content-Type"] = "application/json; charset=utf-8 "
          headers["Accept"] = "application/json"
          headers["Host"] = self.config.host
          headers["Connection"] = "close"
        end
        log:action(msg.HttpAgentSendingPost:tag{host=self.config.host, thread=coroutine.id(), payload=jsonstr})
        self:send("POST "..self.url.." HTTP/1.1\r\n"..table2headers(headers).."\r\n"..jsonstr)
        local code, response, version = self:receive()
        log:action(msg.HttpAgentResponseReceived:tag{host=self.config.host, thread=coroutine.id(), status=code, protocol=version})
        self:close()
        assert(code == 200, response)
      end))
    end,
}

-- tcp service that forwards request to an http service asynchronously

local config = {
  host = "]=]..config.host..[=[",
  port = ]=]..config.port..[=[,
  httpendpoint = "]=]..config.httpendpoint..[=[",
  httpproxy = ]=]..tostring(config.httpproxy)..[=[, -- "localhost:3128"
}

setuplog(log, ]=]..config.auditloglevel..[=[, "]=]..config.auditlogfile..[=[")

local server = newthread(function()
  log:action(msg.HttpAgentStarted:tag{thread=coroutine.id()})

  local service = assert(socket.tcp())
  assert(service:bind(config.host, config.port))
  assert(service:listen())
  service:settimeout(5)

  local shouldrun = true
  while shouldrun do
    local client, status = service:accept()
    if status ~= "timeout" then
      local reader = newthread(function()
        local httpclient = http:connect {
            proxy = config.httpproxy,
            host = config.httpendpoint,
        }
        log:request(msg.HttpAgentClientConnected:tag{thread=coroutine.id()})
        local message, errmsg = "", nil
        repeat
           local result
           result, errmsg = client:receive()
           if result then
             message = message..result
             if message == "shutdown" then -- ask server to shutdown
               message = ""
               shouldrun = false
               unschedule(server)
             end
           end
        until result == nil and errmsg == "closed"
        client:close()
        if message ~= "" then
          httpclient:post("/", message)
        end
        log:request(msg.HttpAgentClientClosed:tag{thread=coroutine.id()})
      end)
      coroutine.yield("last", reader)
    end
  end
  log:action(msg.HttpAgentFinished:tag{thread=coroutine.id()})
end)

-- main loop
assert(schedule(server) == server)
cothread.run()
  ]=])
end

local NullValue = "<EMPTY>"
local UnknownUser = "UNKNOWN_USER"
local KeyValueSeparator = "#"
local NextOptionalSeparator = "$"
local EventSeparator = "\t"

local function serialize(event)
  local str = array.concat(event,"\t")
  str = str..EventSeparator
  local it
  repeat
    local name, value = next(event.optional, it)
    it = name
    str = str..name..KeyValueSeparator..value..
      (next(event.optional, it) and NextOptionalSeparator or "")
  until next(event.optional, it) == nil
  return '[{"body":"'..str..'"}]'
end

local function dateformat(timestamp)
  local mili = string.format("%.3f", timestamp):match("%.(%d%d%d)")
  return date("%Y-%m-%d %H:%M:%S.", math.modf(timestamp))..mili
end

function AuditInterceptor:shutdown()
  local cli = socket.tcp()
  cli:connect(self.config.host, self.config.port)
  cli:send("shutdown\n")
  cli:close()
end

function AuditInterceptor:receiverequest(request, ...)
  BusInterceptor.receiverequest(self, request, ...)
  local chain = self:getCallerChain()
  if chain ~= nil then
    self.auditevents[running()] = {
      uuid.new(), -- id
      "BEEP", -- solution code
      request.operation_name, -- action name
      time(), -- timestamp
      chain.caller.entity or UnknownUser, -- username
      NullValue, -- in (TODO: request parameters)
      (request.success and "true") or
        ((request.success == false) and "false") or NullValue, -- result code
      NullValue, -- out (TODO: results)
      NullValue, -- duration
      "test", -- environment
      optional = {
        endpoint = NullValue,
        packageName = NullValue,
        packageVersion = NullValue,
        serviceName = request.interface.repID,
        ipOrigin = request.channel_address,
        ipDestination = NullValue,
        classification = "NP-1",
      },
    }
  end
end

function AuditInterceptor:sendreply(request)
  BusInterceptor.sendreply(self, request)
  local ev = self.auditevents[running()]
  if ev ~= nil then
    ev[9] = time() - ev[4] -- duration
    schedule(newthread(function()
      ev.optional.serviceName = tostring(ev.optional.serviceName);
      ev.optional.ipOrigin = string.format("%s:%d ", ev.optional.ipOrigin.host, ev.optional.ipOrigin.port)
      ev[4] = dateformat(ev[4])
      local cli = socket.tcp()
      cli:connect(self.config.host, self.config.port)
      local message = serialize(ev)
      log:action(msg.AuditInterceptorPublishing:tag{event=message})
      cli:send(message.."\n")
      cli:close()
    end))
    self.auditevents[running()] = nil
  end
end

return {
  Interceptor = AuditInterceptor
}

