local string = require "string"
local strfmt = string.format
local os = require "os"
local openbus = require "openbus"
local log = require "openbus.util.logger"
log:flag("warn", true)
log:flag("error", true)

-- process command-line arguments
local bushost, busport, entity, domain, password = ...
bushost = assert(bushost, "o 1o. argumento é o host do barramento")
busport = assert(busport, "o 2o. argumento é a porta do barramento")
busport = assert(tonumber(busport), "o 2o. argumento é um número de porta")
entity = assert(entity, "o 3o. argumento é a entidade a ser autenticada")
domain = assert(domain, "o 4o. argumento é o dominio da senha de autenticação")
local params = {
  bushost = bushost,
  busport = busport,
  entity = entity,
}

-- setup the ORB and connect to the bus
local orb = openbus.initORB()
local OpenBusContext = orb.OpenBusContext
OpenBusContext:setDefaultConnection(
  OpenBusContext:createConnection(bushost, busport))

-- call in protected mode
local ok, result = pcall(function()
  -- login to the bus 
  local conn = OpenBusContext:getCurrentConnection()
  conn:loginByPassword(entity,
                       password or entity,
                       domain)
  assert(conn.bus)
  assert(conn.prvkey)
  assert(conn.buskey)
  -- retrieve facets
  local  IComponent = conn.bus
  local   BusConfig = IComponent:getFacet("IDL:tecgraf/openbus/core/v2_1/services/admin/v1_0/Configuration:1.0")
  local AuditConfig = IComponent:getFacetByName("AuditConfiguration")
  local AuditConfig = AuditConfig:__narrow()

  -- using AuditConfiguration
  local previous = AuditConfig:getAuditEventTemplate()
  log:print("audit event template=", previous)
  local ok, err = pcall(AuditConfig.setAuditEventTemplate, AuditConfig, "instance", "testing")
  assert(ok == false, tostring(err):find("ServiceFailure"))
  AuditConfig:setAuditEventTemplate("environment", "testing")
  local current = AuditConfig:getAuditEventTemplate()
  for i, fields in ipairs(current) do
    if fields.name == "environment" and fields.value ~= "testing" then
      error("set audit event template failed someway, expected environment=testing")
    end
  end

  AuditConfig:setAuditServiceURL("http://localhost:51398")
  AuditConfig:setAuditHttpAuth(conn.buskey:encrypt("fulano:silva"))
  
  AuditConfig:setAuditEnabled(false)
  assert(AuditConfig:getAuditEnabled() == false)
  
  AuditConfig:setAuditEnabled(true)
  assert(AuditConfig:getAuditEnabled() == true)
  
  assert(conn.prvkey:decrypt(AuditConfig:getAuditHttpAuth()) == "fulano:silva")
  AuditConfig:setAuditHttpAuth(conn.buskey:encrypt("\0"))
  assert(conn.prvkey:decrypt(AuditConfig:getAuditHttpAuth()) == "")
  assert(AuditConfig:getAuditHttpProxy() == "")
  
  AuditConfig:setAuditHttpProxy("localhost:3128")
  assert(AuditConfig:getAuditHttpProxy() == "localhost:3128")
  -- execute some call to produce audit events
  IComponent:getComponentId()
  AuditConfig:setAuditHttpProxy("")
  assert(AuditConfig:getAuditHttpProxy() == "")
  -- execute some call to produce audit events
  IComponent:getComponentId()

  assert(AuditConfig:getAuditServiceURL() == "http://localhost:51398")
  AuditConfig:setAuditEnabled(false)
  assert(AuditConfig:getAuditEnabled() == false)
  AuditConfig:setAuditServiceURL("http://google.com")
  assert(AuditConfig:getAuditServiceURL() == "http://google.com")
  AuditConfig:setAuditEnabled(true)
  -- execute some call to produce audit events
  IComponent:getComponentId()
  IComponent:getComponentId()

  local limit = AuditConfig:getAuditFIFOLimit()
  assert(limit == 100000, "fifo limit expected 100000 but got "..limit)
  AuditConfig:setAuditFIFOLimit(1)
  -- execute some call to produce audit events
  IComponent:getComponentId()
  IComponent:getComponentId()

  AuditConfig:setAuditFIFOLimit(limit)
  assert(AuditConfig:getAuditDiscardOnExit() == false)
  AuditConfig:setAuditDiscardOnExit(true)
  -- execute some call to produce audit events
  IComponent:getComponentId()
  IComponent:getComponentId()

  AuditConfig:setAuditEnabled(false)
  assert(AuditConfig:getAuditPublishingTasks() == 5)
  AuditConfig:setAuditPublishingTasks(20)
  AuditConfig:setAuditEnabled(true)
  local ok, err = pcall(AuditConfig.setAuditPublishingTasks, AuditConfig, 5)
  assert(ok == false and tostring(err):find("ServiceFailure"))

  assert(AuditConfig:getAuditDiscardOnExit() == true)
  AuditConfig:setAuditDiscardOnExit(false)
  assert(AuditConfig:getAuditPublishingRetryTimeout() == 5)
  AuditConfig:setAuditPublishingRetryTimeout(1)
  for i=1, 200 do
    IComponent:getComponentId() -- execute some call to produce audit events
  end
  log:print("fifolength after 200 calls=", AuditConfig:getAuditFIFOLength())
  AuditConfig:setAuditEnabled(false)
  AuditConfig:setAuditServiceURL("http://localhost:51398")
  AuditConfig:setAuditPublishingTasks(5)
  AuditConfig:setAuditPublishingRetryTimeout(5)
  -- IComponent:shutdown()
end)

-- free any resoures allocated
OpenBusContext:getCurrentConnection():logout()
orb:shutdown()

-- show eventual errors or call services found
if not ok then
  log:unexpected(result)
  os.exit(1)
end
