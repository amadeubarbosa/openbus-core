local pairs = pairs
local ipairs = ipairs
local print = print
local type = type

module "core.test.lua.registry.utils"

-------------------------------------------------------------------------------
-- Funções auxiliares

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

-- Verifica se propsA contém propsB
function contains(self, propsA, propsB)
  for nameB, valuesB in pairs(propsB) do
    -- Verifica se a propriedade existe
    local valuesA = propsA[nameB]
    if not valuesA then
      return false
    end
    -- Verifica se os valores da propriedade são iguais
    for vB in pairs(valuesB) do
      if not valuesA[vB] then
        return false
      end
    end
  end
  return true
end

-- Verifica se duas propriedades são iguais
function equalsProps(self, propsA, propsB)
  local propsA = self:props2hash(propsA)
  local propsB = self:props2hash(propsB)
  
  -- Só é verdade de as duas forem iguais
  return (self:contains(propsA, propsB) and self:contains(propsB, propsA))
end
