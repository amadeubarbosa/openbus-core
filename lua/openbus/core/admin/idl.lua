local _G = require "_G"
local ipairs = _G.ipairs

local array = require "table"
local unpack = array.unpack

local makeaux = require "openbus.core.idl.makeaux"
local parsed = require "openbus.core.admin.parsed"



local types, values, throw = {}, {}, {}
for _, parsed in ipairs(parsed) do
  if parsed.name == "tecgraf" then
    makeaux(parsed, types, values, throw)
  end
end

local idl = {
  types = types.tecgraf.openbus.core.v2_1,
  values = values.tecgraf.openbus.core.v2_1,
  throw = throw.tecgraf.openbus.core.v2_1,
}

function idl.loadto(orb)
  orb.TypeRepository.registry:register(unpack(parsed))
end

return idl
