-----------------------------------------------------------------------------
-- Member: Interface implementada por todos os componentes que se conectam
--         ao OpenBus
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "scs.IComponent"
require "scs.IMetaInterface"

local oop = require "loop.multiple"

Member = oop.class({}, IComponent, IMetaInterface)

function Member:getName()
  return self.name
end
