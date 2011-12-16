local _G = require "_G"
local pcall = _G.pcall
local pcall = _G.pcall
local string = _G.string

local oil = require "oil"
local oillog = require "oil.verbose"

local openbus = require "openbus"
local log = require "openbus.util.logger"
local server = require "openbus.util.server"
local setuplog = server.setuplog

local idl = require "openbus.core.idl"
local loginconst = idl.const.services.access_control
local logintypes = idl.types.services.access_control

-- Configurações --------------------------------------------------------------
local host = "localhost"
local port = 2089
local dUser = "tester"
local dPassword = "tester"
local certificate = "teste.crt"  
local pkey = "teste.key"
local loglevel = 5
local oillevel = 0 

local scsutils = require ("scs.core.utils")()
local props = {}
scsutils:readProperties(props, "test.properties")
scsutils = nil

host = props:getTagOrDefault("host", host)
port = props:getTagOrDefault("port", port)
dUser = props:getTagOrDefault("login", dUser)
dPassword = props:getTagOrDefault("password", dPassword)
certificate = props:getTagOrDefault("certificate", certificate)
pkey = props:getTagOrDefault("privatekey", pkey)
sdklevel = props:getTagOrDefault("sdkLogLevel", sdklevel)
oillevel = props:getTagOrDefault("oilLogLevel", oillevel)

-- Casos de Teste -------------------------------------------------------------
Suite = {}
Suite.Test1 = {}

-- Aliases
local LRCase = Suite.Test1

-- Funções auxiliares ---------------------------------------------------------


-- Inicialização --------------------------------------------------------------
setuplog(log, loglevel)
setuplog(oillog, oillevel)

-- Testes do LoginRegistry ----------------------------------------------------

-- -- IDL operations
-- function LoginRegistry:getAllLogins()
-- function LoginRegistry:getEntityLogins(entity)
-- function LoginRegistry:terminateLogin(id)
-- function LoginRegistry:getLoginInfo(id)
-- function LoginRegistry:getValidity(ids)
-- function LoginRegistry:subscribeObserver(callback)

function LRCase.beforeTestCase(self)
  local conn = openbus.connectByAddress(host, port)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
  self.logins = conn.logins
end

function LRCase.afterTestCase(self)
  self.conn:logout()
  self.conn = nil
  self.logins = nil
end

function LRCase.testGetAllLogins()
  
end

function LRCase.testGetEntityLogins()
  
end

function LRCase.testTerminateLogin()
  
end

function LRCase.testGetLoginInfo()
  
end

function LRCase.testGetValidity()
  
end

function LRCase.testSubscribeObserver()
  
end
