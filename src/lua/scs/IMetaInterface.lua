local oop = require "loop.base"

IMetaInterface = oop.class({})

function IMetaInterface:getFacets()
    local facetDescriptionArray = {}
    for _, facetDescription in pairs(self.facetDescriptionsByName) do
        table.insert(facetDescriptionArray, facetDescription)
    end
    return facetDescriptionArray
end

function IMetaInterface:getFacetsByName(names)
    local facetDescriptionArray = {}
    for _, name in ipairs(names) do
        local facetDescription = self.facetDescriptionsByName[name]
        if facetDescription == nil then
            error{"IDL:SCS/InvalidName:1.0", name = name}
        end
        table.insert(facetDescriptionArray, facetDescription)
    end
    return facetDescriptionArray
end

function IMetaInterface:getReceptacles()
    return {}
end

function IMetaInterface:getReceptaclesByName(names)
    return {}
end
