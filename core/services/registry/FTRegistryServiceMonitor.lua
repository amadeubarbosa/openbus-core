-- $Id

local os = os
local loadfile = loadfile
local assert = assert
local string = string
local format = string.format
local oil = require "oil"

local orb = oil.orb

local tostring = tostring
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


orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_VERSION.."/registry_service.idl")
---
--Componente respons�vel pelo Monitor do Servi�o de Registro
---
module("core.services.registry.FTRegistryServiceMonitor")

------------------------------------------------------------------------------
-- Faceta FTRSMonitorFacet
------------------------------------------------------------------------------

FTRSMonitorFacet = oop.class{}


---
--Obt�m a faceta FT do Servi�o de registro.
--
--@return A faceta do Servi�o de registro, ou nil caso n�o tenha sido definido.
---
function FTRSMonitorFacet:getService()
  local recep =  self.context.IReceptacles
  recep = Openbus:getORB():narrow(recep, "IDL:scs/core/IReceptacles:1.0")
  local status, conns = oil.pcall(recep.getConnections, recep,
      "IFaultTolerantService")
  if not status then
    Log:error("N�o foi poss�vel obter o a faceta de toler�ncia a falhas do servi�o de registro",
        conns)
    return nil
  elseif conns[1] then
    local service = conns[1].objref
    service = Openbus:getORB():narrow(service, Utils.FAULT_TOLERANT_SERVICE_INTERFACE)
    return orb:newproxy(service, "protected")
  end
  Log:error("N�o foi poss�vel obter o a faceta de toler�ncia a falhas do servi�o de registro")
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
      path .. ' usu�rio = ' .. user ..'. host = ' .. host ..
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
--Monitora o servi�o de registro e cria uma nova r�plica se necess�rio.
---
function FTRSMonitorFacet:monitor()
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
      --se objeto remoto est� em estado de falha, precisa ser reinicializado
      if not res then
        reinit = true
          Log:info("O servi�o de registro est� em estado de falha. O servi�o ser� finalizado")
        --pede para o objeto se matar
        self:getService():kill()
      end
    else
      Log:info(format(
          "O servi�o de registro localizado em {%s:%d} n�o est� acess�vel",
          self.config.registryServerHostName, self.config.registryServerHostPort))

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
          local status, void = oil.pcall(ftRec.disconnect, ftRec, self.recConnId)
          if not status then
            Log:error("N�o foi poss�vel desconectar o servi�o de registro do recept�culo")
            return
          end
        end
        Log:info("Reiniciando o servi�o de registro...")

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

        -- Espera alguns segundos para que d� tempo do SR ter sido levantado
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
          Log:warn(format(
              "N�o foi poss�vel reiniciar o servi�o de registro possivelmente porque porta est� bloqueada. Aguardando %d segundos para nova tentativa",
              timeOut.monitor.sleep))
          oil.sleep(timeOut.monitor.sleep)
        end

        timeToTry = timeToTry + 1
      until self.recConnId ~= nil or timeToTry == timeOut.monitor.MAX_TIMES
      if self.recConnId == nil then
         Log:error("[Monitor SR] Servico de registro nao encontrado.")
         os.exit(1)
      end

      Log:info("O servi�o de registro foi reiniciado")
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
    Log:error("O servi�o de registro n�o foi encontrado")
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
end



