local array = require "table"

local oil = require "oil"

local openbus = require "openbus"

local table = require "loop.table"
local cached = require "loop.cached"
local checks = require "loop.test.checks"
local Fixture = require "loop.test.Fixture"
local Suite = require "loop.test.Suite"

local idl = require "openbus.core.idl"
local BusLogin = idl.const.BusLogin
local BusEntity = idl.const.BusEntity

local util = require "openbus.util.server"

-- Configurações --------------------------------------------------------------

require "openbus.test.util"

setorbcfg()

busref = assert(util.readfrom(busref, "r"))
local connprops = { accesskey = openbus.newKey() }

-- Casos de Teste -------------------------------------------------------------

do
  local function checkResults(casedesc, ok, ...)
    local except = casedesc.except
    if except ~= nil then
      checks.assert(ok, checks.equal(false, "operation didn't raise an error"))
      checks.assert(..., except)
    else
      checks.assert(ok, checks.equal(true, ...))
      for index = 1, select("#", ...) do
        local value = select(index, ...)
        checks.assert(value, casedesc.result[index])
      end
    end
  end
  function makeSimpleTests(objects)
    local suite = {}
    for name, cases in pairs(objects) do
      if type(cases) == "function" then
        suite[name] = cases
      else
        for opname, test in pairs(cases) do
          for casename, casedesc in pairs(test) do
            suite[name..":"..opname.."@"..casename] = function (fixture, ...)
              local facet = fixture[name]
              local params = casedesc.params
              for index, value in pairs(params) do
                if type(value) == "function" then
                  params[index] = value(fixture, ...)
                end
              end
              checkResults(casedesc,
                pcall(facet[opname], facet,
                  array.unpack(params, 1, params.n)))
            end
          end
        end
      end
    end
    return suite
  end
end

function assertCondOrTimeout(condition, timeout)
  if timeout == nil then timeout = 3 end
  local deadline = oil.time()+timeout
  while not condition() do
    if oil.time() > deadline then
      error("Assert failed after "..tostring(timeout).." seconds.",2)
    end
    oil.sleep(.1)
  end
end

function newObserver(methods, context)
  local events = {}
  local obs = {}
  function obs:_wait(name, timeout)
    assertCondOrTimeout(function()
      return events[name] ~= nil
    end, timeout)
    local info = events[name]
    events[name] = nil
    if context ~= nil then
      local defconn = context:getDefaultConnection()
      checks.assert(info.chain, checks.like({
        busid = defconn.busid,
        target = defconn.login.entity,
        caller = {
          id = BusLogin,
          entity = BusEntity,
        },
        originators = {},
      }, nil, {isomorphic=true}))
    end
    return array.unpack(info)
  end
  function obs:_get(name)
    local info = events[name]
    if info ~= nil then
      events[name] = nil
      return array.unpack(info)
    end
  end
  for name in pairs(methods) do
    obs[name] = function (self, ...)
      local info = array.pack(...)
      if context ~= nil then
        local chain = context:getCallerChain()
        chain.encoded = nil
        chain.signature = nil
        chain.legacy = nil
        info.chain = chain
      end
      events[name] = info
    end
  end
  return obs
end


local Entities = {
  user = { "loginByPassword", user, password, domain },
  admin = { "loginByPassword", admin, admpsw, domain },
  system = { "loginByCertificate", system, assert(openbus.readKeyFile(syskey)) },
}

OpenBusFixture = cached.class({}, Fixture)

function OpenBusFixture:setup()
  self.orb = openbus.initORB(table.copy(orbcfg))
  self.context = self.orb.OpenBusContext
  local idlloaders = self.idlloaders
  if idlloaders ~= nil then
    for _, loader in ipairs(idlloaders) do
      loader(self.orb)
    end
  end
end

function OpenBusFixture:teardown()
  self.orb:shutdown()
  self.orb = nil
  self.context = nil
end


IdentityFixture = cached.class({}, Fixture)

function IdentityFixture:newConn(kind)
  local bus = self.openbus.orb:newproxy(busref, nil, "scs::core::IComponent")
  local conn = self.openbus.context:connectByReference(bus, connprops)
  if kind ~= nil then
    local info = assert(Entities[kind], "invalid identity kind")
    conn[ info[1] ](conn, array.unpack(info, 2))
  end
  self.connections[conn] = true
  return conn
end

function IdentityFixture:setup(openbus)
  self.openbus = openbus
  self.connections = {}
  local context = openbus.context
  local identity = self.identity
  if identity ~= nil then
    self.defaultConn = context:setDefaultConnection(self:newConn(identity))
    self.currentConn = context:setCurrentConnection(nil)
  end
  self.joinedChain = context:exitChain()
end

function IdentityFixture:teardown(openbus)
  local context = openbus.context
  context:setDefaultConnection(self.defaultConn)
  context:setCurrentConnection(self.currentConn)
  context:joinChain(self.joinedChain)
  self.defaultConn = nil
  self.currentConn = nil
  self.joinedChain = nil
  for conn in pairs(self.connections) do
    conn:logout()
  end
  self.connections = nil
  self.openbus = nil
end
