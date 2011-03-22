-- $Id

local os = os
local tostring = tostring
local loadfile = loadfile
local assert = assert
local string = string
local format = string.format

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

local BIN_DIR = os.getenv("OPENBUS_HOME") .. "/core/bin"

orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_VERSION.."/access_control_service.idl")

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
--ObtÃ©m a faceta FT do ServiÃ§o de Controle de Acesso.
--
--@return A faceta do ServiÃ§o de Controle de Acesso, ou nil caso nÃ£o tenha sido definido.
---
function FTACSMonitorFacet:getService()
  local recep =  self.context.IReceptacles
  recep = Openbus:getORB():narrow(recep, "IDL:scs/core/IReceptacles:1.0")
  local status, conns = oil.pcall(recep.getConnections, recep,
      "IFaultTolerantService")
  if not status then
    Log:error("Nao foi possivel obter o Serviço: " .. conns[1])
    return nil
  elseif conns[1] then
    local service = conns[1].objref
    service = Openbus:getORB():narrow(service, Utils.FAULT_TOLERANT_SERVICE_INTERFACE)
    return orb:newproxy(service, "protected")
  end
  Log:error("Nao foi possivel obter o ServiÃ§o.")
  return nil
end

function FTACSMonitorFacet:sendMail()
  path = os.getenv("OPENBUS_HOME")
  user = os.getenv("USER")
  host = self.config.hostName
  port = self.config.hostPort
  os.execute('echo "Erro no barramento (ACS) em: path = ' ..
      path .. ' usuÃ¡rio = ' .. user ..'. host = ' .. host ..
      '. port = ' .. port ..
      '" | mail -s "Falha no barramento" ' .. self.config.adminMail)
end

function FTACSMonitorFacet:connect()
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


---
--Monitora o servico de controle de acesso e cria uma nova replica se necessario.
---
function FTACSMonitorFacet:monitor()
  local timeOut = assert(loadfile(DATA_DIR .."/conf/FTTimeOutConfiguration.lua"))()
  local ftRec = self.context.IReceptacles
  ftRec = Openbus:getORB():narrow(ftRec, "IDL:scs/core/IReceptacles:1.0")

  while true do
    local reinit = false
    local service = self:getService()
    local ok, res
    if OilUtilities:existent(service) then
      ok, res = service:isAlive()
    end

    --verifica se metodo conseguiu ser executado - isto eh, se nao ocoreu falha de comunicacao
    if ok then
      --se objeto remoto esta em estado de falha, precisa ser reinicializado
      if not res then
        reinit = true
        Log:info("O serviço de controle de acesso está em estado de falha. O serviço será finalizado")
        --pede para o objeto se matar
        self:getService():kill()
      end
    else
      Log:info(format("O serviço de controle de acesso localizado em {%s:%d} não está acessível",
         self.config.hostName, self.config.hostPort))
      -- ocorreu falha de comunicacao com o objeto remoto
      reinit = true
    end

    if not reinit then
      oil.sleep(timeOut.monitor.sleep)
    else
      Log:info("Enviando email para o administrador do barramento")
      self:sendMail()
      local timeToTry = 0


      repeat
        if self.recConnId ~= nil then
          local status, err = oil.pcall(ftRec.disconnect, ftRec, self.recConnId)
          if not status then
            Log:error("Não foi possível desconectar o serviço de controle de acesso do receptáculo")
            return
          end
        end

        Log:info("Reiniciando o serviço de controle de acesso...")

        --Criando novo processo assincrono
        if self:isUnix() then
          os.execute(BIN_DIR.."/run_access_control_server.sh --port=".. self.config.hostPort .. " &")
        else
          os.execute("start "..BIN_DIR.."/run_access_control_server.sh --port=".. self.config.hostPort)
        end

        -- Espera alguns segundos para que dê tempo do SCA ter sido levantado
        oil.sleep(timeOut.monitor.sleep)

        self.recConnId = nil

        Openbus:_reset()
        self:connect()
        if Openbus:isConnected() then
          local ftacsService = Openbus.ft
          self.recConnId = ftRec:connect("IFaultTolerantService",ftacsService)
          if not self.recConnId then
            Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTACSMonitor")
            os.exit(1)
          end
        else
          Log:warn(format(
              "Não foi possível reiniciar o serviço de controle de acesso possivelmente porque porta está bloqueada. Aguardando %d segundos para nova tentativa",
              timeOut.monitor.sleep))
          oil.sleep(timeOut.monitor.sleep)
        end

        timeToTry = timeToTry + 1
      until self.recConnId ~= nil or timeToTry == timeOut.monitor.MAX_TIMES

      if self.recConnId == nil then
        Log:error("O serviço de controle de acesso não pôde ser reiniciado")
        os.exit(1)
      end

      Log:info("O serviço de controle de acesso foi reiniciado")
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

  Openbus:setInterceptable("IDL:scs/core/IReceptacles:1.0", "disconnect", false)

  local ftRec = self.context.IReceptacles
  ftRec = Openbus:getORB():narrow(ftRec, "IDL:scs/core/IReceptacles:1.0")
  local connId = ftRec:connect("IFaultTolerantService",Openbus.ft)
  if not connId then
    Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTACSMonitor")
    error{"IDL:scs/core/StartupFailed:1.0"}
  end

  monitor.recConnId = connId
end
