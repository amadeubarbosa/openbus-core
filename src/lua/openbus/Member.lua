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

function Member:__init(obj)
  IComponent:__init(obj)
  return oop.rawnew(self, obj)
end

function Member:getName()
  return self.name
end
