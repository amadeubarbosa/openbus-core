-- $Id

local os = os
local tostring = tostring
local print = print
local loadfile = loadfile
local assert = assert

local oil = require "oil"
local orb = oil.orb
local Utils = require "openbus.util.Utils"
local Log = require "openbus.util.Log"
local Openbus = require "openbus.Openbus"
local OilUtilities = require "openbus.util.OilUtilities"
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

orb:loadidlfile(IDLPATH_DIR.."/v"..Utils.OB_VERSION.."/access_control_service.idl")

---
--Componente (membro) responsavel pelo Monitor do Servico de Controle de Acesso
---
module("core.services.accesscontrol.FTAccessControlServiceMonitor")

------------------------------------------------------------------------------
-- Faceta FTACSMonitorFacet -- IFTServiceMonitor
------------------------------------------------------------------------------

FTACSMonitorFacet = oop.class{}

function FTACSMonitorFacet:isUnix()
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
--Obtém a faceta FT do Serviço de Controle de Acesso.
--
--@return A faceta do Serviço de Controle de Acesso, ou nil caso não tenha sido definido.
---
function FTACSMonitorFacet:getService()
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
    return service
  end
  log:error("Nao foi possivel obter o Serviço.")
  return nil
end

function FTACSMonitorFacet:sendMail()
  path = os.getenv("OPENBUS_HOME")
  user = os.getenv("USER")
  host = self.config.hostName
  port = self.config.hostPort
  os.execute('echo "Erro no barramento (ACS) em: path = ' ..
      path .. ' usuário = ' .. user ..'. host = ' .. host ..
      '. port = ' .. port ..
      '" | mail -s "Falha no barramento" ' .. self.config.adminMail)
end

function FTACSMonitorFacet:connect()
  Openbus:init(self.config.hostName, self.config.hostPort)
  Openbus.isFaultToleranceEnable = false
  Openbus:_setInterceptors()
  -- autentica o monitor, conectando-o ao barramento
  Openbus:connectByCertificate(self.context._componentId.name,
      DATA_DIR.."/"..self.config.monitorPrivateKeyFile,
      DATA_DIR.."/"..self.config.accessControlServiceCertificateFile)
end


---
--Monitora o servico de controle de acesso e cria uma nova replica se necessario.
---
function FTACSMonitorFacet:monitor()
  Log:faulttolerance("[Monitor SCA] Inicio")
  local timeOut = assert(loadfile(DATA_DIR .."/conf/FTTimeOutConfiguration.lua"))()

  while true do
    local reinit = false
    local ok, res = self:getService().__try:isAlive()
    Log:faulttolerance("[Monitor SCA] isAlive? "..tostring(ok))

    --verifica se metodo conseguiu ser executado - isto eh, se nao ocoreu falha de comunicacao
    if ok then
      --se objeto remoto esta em estado de falha, precisa ser reinicializado
      if not res then
        reinit = true
        Log:faulttolerance("[Monitor SCA] Servico de Controle de Acesso em estado de falha. Matando o processo...")
        --pede para o objeto se matar
        self:getService():kill()
      end
    else
      Log:faulttolerance("[Monitor SCA] Servico de Controle de Acesso nao esta disponivel...")
      -- ocorreu falha de comunicacao com o objeto remoto
      reinit = true
    end

    if not reinit then
      oil.sleep(timeOut.monitor.sleep)
    else
      Log:faulttolerance("Enviando email para o administrador do barramento.")
      self:sendMail()
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

          Log:faulttolerance("[Monitor SCA] disconnect executed successfully!")
        end

        Log:faulttolerance("[Monitor SCA] Levantando Servico de Controle de Acesso...")

        --Criando novo processo assincrono
        if self:isUnix() then
          --os.execute(BIN_DIR.."/run_access_control_server.sh --port=".. self.config.hostPort..
          --           " &  > log_access_control_server-"..tostring(t)..".txt")
          os.execute(BIN_DIR.."/run_access_control_server.sh --port=".. self.config.hostPort)
        else
          --os.execute("start "..BIN_DIR.."/run_access_control_server.sh --port=".. self.config.hostPort..
          --           " > log_access_control_server-"..tostring(t)..".txt")
          os.execute("start "..BIN_DIR.."/run_access_control_server.sh --port=".. self.config.hostPort)
        end

        -- Espera alguns segundos para que dê tempo do SCA ter sido levantado
        oil.sleep(timeOut.monitor.sleep)

        self.recConnId = nil
        self:connect()
        if Openbus:isConnected() then
          local ftacsService = Openbus.ft

          local ftRec = self.context.IReceptacles
          ftRec = Openbus:getORB():narrow(ftRec, "IDL:scs/core/IReceptacles:1.0")
          self.recConnId = ftRec:connect("IFaultTolerantService",ftacsService)
          if not self.recConnId then
            Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTACSMonitor")
            os.exit(1)
          end
        else
          Log:faulttolerance("[Monitor SCA] N�o conseguiu levantar ACS de primeira possivelmente porque porta est� bloqueada.")
          Log:faulttolerance("[Monitor SCA] Espera " .. tostring(timeOut.monitor.sleep) .." segundos......")
          oil.sleep(timeOut.monitor.sleep)
        end

        timeToTry = timeToTry + 1
      until self.recConnId ~= nil or timeToTry == timeOut.monitor.MAX_TIMES

      if self.recConnId == nil then
        Log:error("[Monitor SCA] Servico de controle de acesso nao pode ser levantado.")
        os.exit(1)
      end

      Log:faulttolerance("[Monitor SCA] Servico de Controle de Acesso criado.")
    end
  end
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
  local connId = ftRec:connect("IFaultTolerantService",Openbus.ft)
  if not connId then
    Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTACSMonitor")
    os.exit(1)
  end

  monitor.recConnId = connId
  Log:init("Monitor do servico de controle de acesso iniciado com sucesso")
end
