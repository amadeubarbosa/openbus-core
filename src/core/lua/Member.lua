-----------------------------------------------------------------------------
-- Member: Interface implementada por todos os componentes que se conectam
--         ao OpenBus
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
require "OOP"

require "IComponent"
require "IMetaInterface"

Member = createClass(IComponent, IMetaInterface)

function Member:getName()
  return self.name
end
