require "OOP"

IComponent = createClass()

IComponent.facets = {}
IComponent.facetsByName = {}

function IComponent:getFacet(facet_interface)
    return self.facets[facet_interface]
end

function IComponent:getFacetByName(facet)
    return self.facetsByName[facet]
end
