-----------------------------------------------------------------------------
-- Member: Interface implementada por todos os componentes que se conectam
--         ao OpenBus
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "OOP"

require "IComponent"
require "IMetaInterface"

Member = createClass(IComponent, IMetaInterface)

function Member:getName()
  return self.name
end
