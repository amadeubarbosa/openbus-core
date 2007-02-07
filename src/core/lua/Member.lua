-----------------------------------------------------------------------------
-- Member: Interface implementada por todos os componentes que se conectam
--         ao OpenBus
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
require "IComponent"
require "IMetaInterface"

local oop = require "loop.multiple"

Member = oop.class({}, IComponent, IMetaInterface)

function Member:getName()
  return self.name
end
