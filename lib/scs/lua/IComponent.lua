local pairs = pairs

local oil = require "oil"

local IMetaInterface = require "scs.core.IMetaInterface"

local oop = require "loop.base"

module("scs.core.IComponent", oop.class)

function __init(self, name, version)
  local component = oop.rawnew(self, {
    componentId = {name = name, version = version},
    facetDescriptionsByName = {},
  })
  local metaInterface = IMetaInterface(component)
  component:addFacet("IMetaInterface", "IDL:scs/core/IMetaInterface:1.0",
      metaInterface)
  return component
end

function getFacet(self, facet_interface)
  for _, facetDescription in pairs(self.facetDescriptionsByName) do
    if facetDescription.interface_name == facet_interface then
      return facetDescription.facet_ref
    end
  end
  return nil
end

function getFacetByName(self, facet)
  local facetDescription = self.facetDescriptionsByName[facet]
  if not facetDescription then
    return nil
  end
  return facetDescription.facet_ref
end

function getComponentId(self)
  return self.componentId
end

function addFacet(self, name, interface_name, facet_servant)
  local facet_ref = oil.newservant(facet_servant, interface_name)
  local facetDescription = {
    name = name,
    interface_name = interface_name,
    facet_ref = facet_ref,
  }
  self.facetDescriptionsByName[name] = facetDescription
  return facet_ref
end

function removeFacets(self)
  for _, facetDescription in pairs(self.facetDescriptionsByName) do
    facetDescription.facet_ref:_deactivate()
  end
  self.facetDescriptionsByName = {}
end
