local oop = require "loop.base"

IComponent = oop.class{}

function IComponent:__init(obj)
  obj = obj or {}
  obj.facetDescriptionsByName = {}
  return oop.rawnew(self, obj)
end

function IComponent:getFacet(facet_interface)
    for _, facetDescription in pairs(self.facetDescriptionsByName) do
        if facetDescription.interface_name == facet_interface then
            return facetDescription.facet_ref
        end
    end
    return nil
end

function IComponent:getFacetByName(facet)
    local facetDescription = self.facetDescriptionsByName[facet]
    if not facetDescription then
        return nil
    end
    return facetDescription.facet_ref
end

function IComponent:addFacet(name, interface_name, facet_servant)
    local facet_ref = oil.newservant(facet_servant, interface_name, name)
    local facetDescription = {
        name = name,
        interface_name = interface_name,
        facet_ref = facet_ref,
    }
    self.facetDescriptionsByName[name] = facetDescription
    return facet_ref
end

function IComponent:removeFacets()
    for _, facetDescription in pairs(self.facetDescriptionsByName) do
      facetDescription.facet_ref:_deactivate()
    end
    self.facetDescriptionsByName = {}
end
