require "OOP"

IComponent = Object:new{
    facets = {},

    facetsByName = {},

    getFacet = function(self, facet_interface)
        return self.facets[facet_interface]
    end,

    getFacetByName = function(self, facet)
        return self.facetsByName[facet]
    end,
}
