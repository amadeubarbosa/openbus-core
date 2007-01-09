require "OOP"

IMetaInterface = createClass()

IMetaInterface.facetDescriptionsByName = {}
IMetaInterface.receptacleDescriptionsByName = {}

function IMetaInterface:getFacets()
    local facetDescriptions = {}
    for _, facetDescription in pairs(self.facetDescriptionsByName) do
        table.insert(facetDescriptions, facetDescription)
    end
    return facetDescriptions
end

function IMetaInterface:getFacetsByName(names)
    local facetDescriptions = {}
    for _, name in ipairs(names) do
        local facetDescription = self.facetDescriptionsByName[name]
        if facetDescription == nil then
            error{"IDL:SCS/InvalidName:1.0", name = name}
        end
        table.insert(facetDescriptions, facetDescription)
    end
    return facetDescriptions
end

function IMetaInterface:getReceptacles()
    local receptacleDescriptions = {}
    for _, receptacleDescription in pairs(self.receptacleDescriptionsByName) do
        table.insert(receptacleDescriptions, receptacleDescription)
    end
    return receptacleDescriptions
end

function IMetaInterface:getReceptaclesByName(names)
    local receptacleDescriptions = {}
    for _, name in ipairs(names) do
        local receptacleDescription = self.receptacleDescriptionsByName[name]
        if receptacleDescription == nil then
            error{"IDL:SCS/InvalidName:1.0", name = name}
        end
        table.insert(receptacleDescriptions, receptacleDescription)
    end
    return receptacleDescriptions
end
