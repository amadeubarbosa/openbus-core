-- $Id:

local pairs = pairs
local type = type

local oop = require "loop.simple"
local oil = require "oil"

local Utils = require "openbus.util.Utils"

local Log = require "openbus.util.Log"
---
-- Código responsável pelo Serviço de Registro na versao anterior à atual do barramento.
---
module("core.services.registry.RegistryService_Prev")

------------------------------------------------------------------------------
-- Faceta IRegistryService_Prev
------------------------------------------------------------------------------

RSFacet = oop.class{}

local rsFacetName = "IRegistryService_" .. Utils.IDL_VERSION

function RSFacet:register(serviceOffer)
  local status, ret = oil.pcall(self.context[rsFacetName].register,
                                self.context[rsFacetName],
                                serviceOffer)
  if not status then
    Log:error("Erro na execução do 'register' da versão 1.4")
    Log:error(ret)
    return false, ""
  end
  return true, ret
end

function RSFacet:unregister(identifier)
  return self.context[rsFacetName]:unregister(identifier)
end

function RSFacet:update(identifier, properties)
  local status, ret = oil.pcall(self.context[rsFacetName].update,
                                self.context[rsFacetName],
                                identifier, properties)
  if not status then
    return false
  end
  return true
end

function RSFacet:find(facets)
  return self.context[rsFacetName]:find(facets)
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

  return self.context[rsFacetName]:findByCriteria(facets, criteria)
end

function RSFacet:localFind(facets, criteria)
  return self.context[rsFacetName]:localFind(facets, criteria)
end

