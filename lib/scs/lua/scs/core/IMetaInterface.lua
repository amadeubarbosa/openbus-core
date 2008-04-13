local table = table

local pairs = pairs
local error = error

local oop = require "loop.base"
module("scs.core.IMetaInterface", oop.class)

function __init(self, component)
  return oop.rawnew(self, {
    component = component,
  })
end

function getFacets(self)
  local facetDescriptionArray = {}
  for _, facetDescription in pairs(self.component.facetDescriptionsByName) do
    table.insert(facetDescriptionArray, facetDescription)
  end
  return facetDescriptionArray
end

function getFacetsByName(self, names)
  local facetDescriptionArray = {}
  for _, name in ipairs(names) do
    local facetDescription = self.component.facetDescriptionsByName[name]
    if facetDescription == nil then
      error{"IDL:SCS/InvalidName:1.0", name = name}
    end
    table.insert(facetDescriptionArray, facetDescription)
  end
  return facetDescriptionArray
end

function getReceptacles(self)
  return {}
end

function getReceptaclesByName(self, names)
  return {}
end
