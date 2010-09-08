-- $Id: RegistryService.lua 102795 2010-03-10 20:24:18Z brunoos $

local oop = require "loop.simple"
local oil = require "oil"

local pairs = pairs
local type = type
local string = string

---
--Componente (membro) responsável pelo Serviço de Registro na versao 1.04.
---
module("core.services.registry.RegistryService_v1_04")

------------------------------------------------------------------------------
-- Faceta IRegistryService
------------------------------------------------------------------------------

RSFacet = oop.class{}

function RSFacet:register(serviceOffer)
  local status, ret = oil.pcall(self.context.IRegistryService.register,
                                self.context.IRegistryService,
                                serviceOffer)
  if not status then
    return false, ""
  end
  return true, ret
end

function RSFacet:unregister(identifier)
  return self.context.IRegistryService:unregister(identifier)
end

function RSFacet:update(identifier, properties)
  local status, ret = oil.pcall(self.context.IRegistryService.update,
                                self.context.IRegistryService,
                                identifier, properties)
  if not status then
    return false
  end
  return true
end

function RSFacet:find(facets)
  return self.context.IRegistryService:find(facets)
end

function RSFacet:findByCriteria(facets, criteria)
  -- Troca valor de component_id de "nome:100", para "nome:1.0.0".
  for _,props in pairs(criteria) do
    if type(props) == "table" and props.name == "component_id" then
        local componentId = props.value[1]
        local newCompId = componentId:gsub("(.+):(%d)(%d)(%d)","%1:%2.%3.%4")
        if newCompId then
          props.value[1] = newCompId
        end
    end
  end

  return self.context.IRegistryService:findByCriteria(facets, criteria)
end

function RSFacet:localFind(facets, criteria)
  return self.context.IRegistryService:localFind(facets, criteria)
end

