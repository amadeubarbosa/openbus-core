require "OOP"

require "IComponent"
require "IMetaInterface"

Member = createClass(IComponent, IMetaInterface)

function Member:getName()
    return self.name
end
