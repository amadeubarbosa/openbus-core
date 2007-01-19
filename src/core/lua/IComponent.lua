require "OOP"

IComponent = createClass()

IComponent.facetDescriptionsByName = {}

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

function IComponent:addFacet(name, interface_name, facet_ref)
    local facetDescription = {
        name = name,
        interface_name = interface_name,
        facet_ref = facet_ref,
    }
    self.facetDescriptionsByName[name] = facetDescription
end

function IComponent:removeFacets()
    self.facetDescriptionsByName = {}
end
