-- $Id

local os = os
local loadfile = loadfile
local assert = assert

local oil = require "oil"

local orb = oil.orb

local tostring = tostring
local print = print
local pairs = pairs

--local IComponent = require "scs.core.IComponent"
local Log = require "openbus.util.Log"
local Openbus = require "openbus.Openbus"
local OilUtilities = require "openbus.util.OilUtilities"
local utils = require "openbus.util.Utils"

local oop = require "loop.simple"

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")


if IDLPATH_DIR == nil then
  Log:error("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end


local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

local BIN_DIR = os.getenv("OPENBUS_DATADIR") .. "/../core/bin"

Log:level(4)
oil.verbose:level(2)


orb:loadidlfile(IDLPATH_DIR.."/registry_service.idl")
---
--Componente responsável pelo Monitor do Serviço de Registro
---
module("core.services.registry.FTRegistryServiceMonitor")

------------------------------------------------------------------------------
-- Faceta FTRSMonitorFacet
------------------------------------------------------------------------------

FTRSMonitorFacet = oop.class{}


---
--Obtém a faceta FT do Serviço de registro.
--
--@return A faceta do Serviço de registro, ou nil caso não tenha sido definido.
---
function FTRSMonitorFacet:getService()
  local recep =  self.context.IReceptacles
  recep = Openbus:getORB():narrow(recep, "IDL:scs/core/IReceptacles:1.0")
  local status, conns = oil.pcall(recep.getConnections, recep,
      "IFaultTolerantService")
  if not status then
    log:error("Nao foi possivel obter o Serviço: " .. conns[1])
    return nil
  elseif conns[1] then 
    local service = conns[1].objref
    service = Openbus:getORB():narrow(service, "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0")
    return service
  end
  log:error("Nao foi possivel obter o Serviço.")
  return nil
end

function FTRSMonitorFacet:connect()
  Openbus:init(self.config.accessControlServerHostName, 
      self.config.accessControlServerHostPort)
  Openbus:_setInterceptors()
  Openbus:enableFaultTolerance()

  -- autentica o monitor, conectando-o ao barramento
  Openbus:connectByCertificate(self.context._componentId.name,
      DATA_DIR.."/"..self.config.monitorPrivateKeyFile, 
      DATA_DIR.."/"..self.config.accessControlServiceCertificateFile)
end


function FTRSMonitorFacet:isUnix()
--TODO - Confirmar se vai manter assim
  if os.execute("uname") == 0 then
    --unix
    return true
  else
    --windows
    return false
  end
end

---
--Monitora o serviço de registro e cria uma nova réplica se necessário.
---
function FTRSMonitorFacet:monitor()
  Log:faulttolerance("[Monitor SR] Inicio")
  local timeOut = assert(loadfile(DATA_DIR .."/conf/FTTimeOutConfiguration.lua"))()

  while true do  
    local reinit = false
    local ok, res = self:getService().__try:isAlive()  
    Log:faulttolerance("[Monitor SR] isAlive? "..tostring(ok))  

    --verifica se metodo conseguiu ser executado - isto eh, se nao ocoreu falha de comunicacao
    if ok then
      --se objeto remoto esté em estado de falha, precisa ser reinicializado
      if not res then
        reinit = true
        Log:faulttolerance("[Monitor SR] Servico de registro em estado de falha. Matando o processo...")
        --pede para o objeto se matar
        self:getService():kill()
      end
    else
      Log:faulttolerance("[Monitor SR] Servico de registro nao esta disponivel...")
      -- ocorreu falha de comunicacao com o objeto remoto
      reinit = true
    end

    if reinit then
      Openbus.credentialManager:invalidate()
      Openbus.acs = nil
      local timeToTry = 0

      repeat
        if self.recConnId ~= nil then
          local status, ftRecD = oil.pcall(self.context.IComponent.getFacet, 
              self.context.IComponent, "IDL:scs/core/IReceptacles:1.0")

          if not status then
            print("[IReceptacles::IComponent] Error while calling getFacet(IDL:scs/core/IReceptacles:1.0)")
            print("[IReceptacles::IComponent] Error: " .. ftRecD)
            return
          end
          ftRecD = Openbus:getORB():narrow(ftRecD)
      
          local status, void = oil.pcall(ftRecD.disconnect, ftRecD, self.recConnId)
          if not status then
            print("[IReceptacles::IReceptacles] Error while calling disconnect")
            print("[IReceptacles::IReceptacles] Error: " .. void)
            return
          end
          Log:faulttolerance("[Monitor SR] disconnect executed successfully!")
        end
        Log:faulttolerance("[Monitor SR] Levantando Servico de registro...")

        --Criando novo processo assincrono
        if self:isUnix() then
          os.execute(BIN_DIR.."/run_registry_server.sh --port=".. 
              self.config.registryServerHostPort)
          --os.execute(BIN_DIR.."/run_registry_server.sh --port=".. 
          --self.config.registryServerHostPort.. 
          --" & > log_registry_server-"..tostring(t)..".txt")
        else
          os.execute("start "..BIN_DIR.."/run_registry_server.sh --port="..
              self.config.registryServerHostPort)
          --os.execute("start "..BIN_DIR.."/run_registry_server.sh --port="..
          --self.config.registryServerHostPort..
          --"> log_registry_server-"..tostring(t)..".txt")
        end

        -- Espera alguns segundos para que dê tempo do SR ter sido levantado
        os.execute("sleep ".. tostring(timeOut.monitor.sleep))

        self.recConnId = nil
        self:connect()
        if Openbus:isConnected() then
          local rs = Openbus:getRegistryService()
          local rsIC = rs:_component()
          rsIC = Openbus:getORB():narrow(rsIC, "IDL:scs/core/IComponent:1.0")
          local ftrsService = rsIC:getFacetByName("IFaultTolerantService")
          ftrsService = Openbus:getORB():narrow(ftrsService, 
              "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0")

          if OilUtilities:existent(ftrsService) then
            local ftRec = self:getFacetByName("IReceptacles")
            ftRec = orb:narrow(ftRec)
            self.recConnId = ftRec:connect("IFaultTolerantService",ftrsService)
            if not self.recConnId then
              Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTRSMonitor")
              os.exit(1)
            end
          end
        else
          Log:faulttolerance("[Monitor SR] Não conseguiu levantar RS de primeira porque porta está bloqueada.")
          Log:faulttolerance("[Monitor SR] Espera " .. tostring(timeOut.monitor.sleep) .." segundos......")
          os.execute("sleep ".. tostring(timeOut.monitor.sleep))
        end
        timeToTry = timeToTry + 1

      until self.recConnId ~= nil or timeToTry == timeOut.monitor.MAX_TIMES
      if self.recConnId == nil then
         Log:error("[Monitor SR] Servico de registro nao encontrado.")
         os.exit(1)
      end

      Log:faulttolerance("[Monitor SR] Servico de registro criado.")
    end --fim reinit
  end --fim while
end

--------------------------------------------------------------------------------
-- Faceta IComponent
--------------------------------------------------------------------------------

---
--Inicia o componente.
--
--@see scs.core.IComponent#startup
---
function startup(self)
  local monitor = self.context.IFTServiceMonitor
  monitor:connect()
  
  if not Openbus:isConnected() then
    Log:error("Erro ao se logar no ACS")
    os.exit(1)
  end

  local ftRec = self.context.IReceptacles
  ftRec = Openbus:getORB():narrow(ftRec, "IDL:scs/core/IReceptacles:1.0")

  local hostAdd = monitor.config.registryServerHostName..
      ":".. tostring(monitor.config.registryServerHostPort)

  local ftrsService = Openbus:getORB():newproxy("corbaloc::"..hostAdd.. "/" ..
      utils.FAULT_TOLERANT_RS_KEY,utils.FAULT_TOLERANT_SERVICE_INTERFACE)
  if ftrsService:_non_existent() then
    Log:error("Servico de registro nao encontrado.")
    os.exit(1)
  end

  local connId = ftRec:connect("IFaultTolerantService",ftrsService)
  if not connId then
    Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTRSMonitor")
    os.exit(1)
  end

  monitor.recConnId = connId
  Log:init("Monitor do servico de registro iniciado com sucesso")
end



