-----------------------------------------------------------------------------
-- OOP: Orienta��o a Objetos em Lua, com suporte a heran�a m�ltipla
-- Implementa��o baseada na Se��o 16.3 de PiL
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Procura um m�todo (k) na lista de superclasses (plist)
-----------------------------------------------------------------------------
local function search (k, plist)
  for i = 1, #plist do
    local v = plist[i][k]
    if v then
      return v
    end
  end
end

-----------------------------------------------------------------------------
-- Cria uma nova classe cujo comportamento � herdado da lista de superclasses
-- recebida como par�metro
-----------------------------------------------------------------------------
function createClass (...)
  local c = {}

  setmetatable(c, {__index = function (t, k)
                               return search(k, arg)
                             end})
  c.__index = c

  -- Construtor para a nova classe
  function c:new (o)
    o = o or {}
    setmetatable(o, c)
    return o
  end

  return c
end
