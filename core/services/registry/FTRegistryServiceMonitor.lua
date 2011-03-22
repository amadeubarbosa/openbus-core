-- $Id

local os = os
local loadfile = loadfile
local assert = assert
local string = string

local oil = require "oil"

local orb = oil.orb

local tostring = tostring
local print = print
local pairs = pairs

--local IComponent = require "scs.core.IComponent"
local Log = require "openbus.util.Log"
local Openbus = require "openbus.Openbus"
local OilUtilities = require "openbus.util.OilUtilities"
local Utils = require "openbus.util.Utils"

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

local BIN_DIR = os.getenv("OPENBUS_HOME") .. "/core/bin"


orb:loadidlfile(IDLPATH_DIR.."/v"..Utils.OB_VERSION.."/registry_service.idl")
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
    service = Openbus:getORB():narrow(service, Utils.FAULT_TOLERANT_SERVICE_INTERFACE)
    return orb:newproxy(service, "protected")
  end
  log:error("Nao foi possivel obter o Serviço.")
  return nil
end

function FTRSMonitorFacet:connect()
  local keyConfigPath = self.config.monitorPrivateKeyFile
  local keyAbsolutePath
  if string.match(keyConfigPath, "^/") then
    keyAbsolutePath = keyConfigPath
  else
    keyAbsolutePath = DATA_DIR .. "/" .. keyConfigPath
  end

  local certConfigPath = self.config.accessControlServiceCertificateFile
  local certAbsolutePath
  if string.match(certConfigPath, "^/") then
    certAbsolutePath = certConfigPath
  else
    certAbsolutePath = DATA_DIR .. "/" .. certConfigPath
  end

  -- autentica o monitor, conectando-o ao barramento
  Openbus:connectByCertificate(self.context._componentId.name,
      keyAbsolutePath, certAbsolutePath)
end

function FTRSMonitorFacet:sendMail()
  path = os.getenv("OPENBUS_HOME")
  user = os.getenv("USER")
  host = self.config.registryServerHostName
  port = self.config.registryServerHostPort
  os.execute('echo "Erro no barramento (RGS) em: path = ' ..
      path .. ' usuário = ' .. user ..'. host = ' .. host ..
      '. port = ' .. port ..
      '" | mail -s "Falha no barramento" ' .. self.config.adminMail)
end

function FTRSMonitorFacet:isUnix()
--TODO - Confirmar se vai manter assim
  if os.execute("uname > /dev/null") == 0 then
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
  local ftRec = self.context.IReceptacles
  ftRec = Openbus:getORB():narrow(ftRec, "IDL:scs/core/IReceptacles:1.0")

  while true do
    local reinit = false
    local service = self:getService()
    local ok, res = service:isAlive()
    Log:faulttolerance("[Monitor SR] isAlive? "..tostring(ok))

    --verifica se metodo conseguiu ser executado - isto eh, se nao ocoreu falha de comunicacao
    if ok then
      --se objeto remoto está em estado de falha, precisa ser reinicializado
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

    if not reinit then
      oil.sleep(timeOut.monitor.sleep)
    else
      Log:faulttolerance("Enviando email para o administrador do barramento.")
      self:sendMail()

      local timeToTry = 0

      repeat
        if self.recConnId ~= nil then
          local status, void = oil.pcall(ftRec.disconnect, ftRec, self.recConnId)
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
              self.config.registryServerHostPort .. " &")
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
        oil.sleep(timeOut.monitor.sleep)

        self.recConnId = nil

        local ftrsService = Openbus:getORB():newproxy("corbaloc::"..self.hostAdd.. "/" ..
                                           Utils.FAULT_TOLERANT_RS_KEY,
                                           "synchronous",
                                           Utils.FAULT_TOLERANT_SERVICE_INTERFACE)
        if OilUtilities:existent(ftrsService) then
            self.recConnId = ftRec:connect("IFaultTolerantService",ftrsService)
            if not self.recConnId then
              Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTRSMonitor")
              os.exit(1)
            end
        else
          Log:faulttolerance("[Monitor SR] Nao conseguiu levantar RS de primeira porque porta esta bloqueada.")
          Log:faulttolerance("[Monitor SR] Espera " .. tostring(timeOut.monitor.sleep) .." segundos......")
          oil.sleep(timeOut.monitor.sleep)
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

  monitor.hostAdd = monitor.config.registryServerHostName..
      ":".. tostring(monitor.config.registryServerHostPort)

  local ftrsService = Openbus:getORB():newproxy("corbaloc::"..monitor.hostAdd.. "/" ..
      Utils.FAULT_TOLERANT_RS_KEY,
      "synchronous",
      Utils.FAULT_TOLERANT_SERVICE_INTERFACE)
  if ftrsService:_non_existent() then
    Log:error("Servico de registro nao encontrado.")
    os.exit(1)
  end

  local ftRec = self.context.IReceptacles
  ftRec = Openbus:getORB():narrow(ftRec, "IDL:scs/core/IReceptacles:1.0")

  local connId = ftRec:connect("IFaultTolerantService",ftrsService)
  if not connId then
    Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTRSMonitor")
    os.exit(1)
  end

  monitor.recConnId = connId
  Log:init("Monitor do servico de registro iniciado com sucesso")
end



