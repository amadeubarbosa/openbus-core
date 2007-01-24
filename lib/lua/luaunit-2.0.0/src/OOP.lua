-----------------------------------------------------------------------------
-- OOP: Orientação a Objetos em Lua, com suporte a herança múltipla
-- Implementação baseada na Seção 16.3 de PiL
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Procura um método (k) na lista de superclasses (plist)
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
-- Cria uma nova classe cujo comportamento é herdado da lista de superclasses
-- recebida como parâmetro
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
