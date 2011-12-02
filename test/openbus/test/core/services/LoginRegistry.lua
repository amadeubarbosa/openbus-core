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
local port = "2089"
local admin = "admin"
local adminPassword = "admin"
local dUser = "tester"
local dPassword = "tester"
local certificate = "tester.crt"
local pkey = "tester.key"
local loglevel = 5
local oillevel = 0 

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

function LRCase.testRegisterCertificate()
  
end

function LRCase.testGetCertificate()
  
end

function LRCase.testRemoveCertificate()
  
end

