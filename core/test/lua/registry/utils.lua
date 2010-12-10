local pairs = pairs
local ipairs = ipairs
local print = print
local type = type

module "core.test.lua.registry.utils"

-------------------------------------------------------------------------------
-- Fun��es auxiliares

-- Muda de array para hash
function props2hash(self, props)
  local hash = {}
  for _, prop in ipairs(props) do
    local values = {}
    for _, v in ipairs(prop.value) do
      values[v] = true
    end
    hash[prop.name] = values
  end
  return hash
end

-- Verifica se propsA cont�m propsB
function contains(self, propsA, propsB)
  for nameB, valuesB in pairs(propsB) do
    -- Verifica se a propriedade existe
    local valuesA = propsA[nameB]
    if not valuesA then
      return false
    end
    -- Verifica se os valores da propriedade s�o iguais
    for vB in pairs(valuesB) do
      if not valuesA[vB] then
        return false
      end
    end
  end
  return true
end

-- Verifica se duas propriedades s�o iguais
function equalsProps(self, propsA, propsB)
  local propsA = self:props2hash(propsA)
  local propsB = self:props2hash(propsB)
  
  -- S� � verdade de as duas forem iguais
  return (self:contains(propsA, propsB) and self:contains(propsB, propsA))
end
