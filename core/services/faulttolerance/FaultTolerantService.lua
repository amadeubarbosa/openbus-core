local os = os
local oil = require "oil"

local Log = require "openbus.util.Log"
local Utils   = require "openbus.util.Utils"
local oop = require "loop.simple"

---
--Componente responsável pelo Serviço de Controle de Acesso
---
module("core.services.faulttolerance.FaultTolerantService")

local DATA_DIR = os.getenv("OPENBUS_DATADIR")

--------------------------------------------------------------------------------
-- Faceta IFaultTolerantService
--------------------------------------------------------------------------------

FaultToleranceFacet = oop.class{}
FaultToleranceFacet.faultDescription = {_isAlive = true, _errorMsg = "" }

---
--Retorna se o serviço está em estado de falha ou não.
---

function FaultToleranceFacet:isAlive()
    if not self.faultDescription._isAlive then
       local msg = "Servico ".. self.context._componentId.name .." nao esta disponivel.\n"
       self.faultDescription._errorMsg = msg
       Log:error(msg)
       return false
    end
    return true
end

function FaultToleranceFacet:setStatus(isAlive)
    self.context["IManagement_" .. Utils.IDL_VERSION]:checkPermission()
    self.faultDescription._isAlive = isAlive
end

function FaultToleranceFacet:kill()
    self.context["IManagement_" .. Utils.IDL_VERSION]:checkPermission()
    self.context.IComponent:shutdown()
end
