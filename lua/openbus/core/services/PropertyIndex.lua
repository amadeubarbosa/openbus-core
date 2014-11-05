local _G = require "_G"
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local rawget = _G.rawget
local setmetatable = _G.setmetatable

local table = require "loop.table"
local memoize = table.memoize

local math = require "math"
local inf = math.huge

local oo = require "openbus.util.oo"
local class = oo.class



local ReturnZero = { __index = function() return 0 end }
local function newOfferSet() return {} end
local function newValueIndex() return memoize(newOfferSet) end



local PropertyIndex = class()

function PropertyIndex:__init()
  self.sizeOf = setmetatable({}, ReturnZero)
  self.index = memoize(newValueIndex)
end

function PropertyIndex:add(object)
  local index = self.index
  local sizeOf = self.sizeOf
  for _, prop in ipairs(object.properties) do
    local objects = index[prop.name][prop.value]
    if objects[object] == nil then
      objects[object] = true
      sizeOf[objects] = sizeOf[objects]+1
    end
  end
end

function PropertyIndex:remove(object)
  local index = self.index
  local sizeOf = self.sizeOf
  for _, prop in ipairs(object.properties) do
    local name = prop.name
    local value = prop.value
    local validx = index[name]
    local objects = validx[value]
    local size = sizeOf[objects]
    if size > 1 then
      sizeOf[objects] = size-1
      objects[object] = nil
    else
      sizeOf[objects] = nil
      validx[value] = nil -- last object with this property value was removed
      if next(validx) == nil then
        index[name] = nil -- last object with this property was removed
      end
    end
  end
end

function PropertyIndex:find(properties)
  local found = {}
  local count = #properties
  if count > 0 then
    local index = self.index
    local sizeOf = self.sizeOf
    -- collecting all sets of objects with any of these properties
    -- and find the which of these sets has less objects.
    local sets = {}
    local min_sz, min = inf
    for i = 1, count do
      local prop = properties[i]
      local validx = rawget(index, prop.name)
      if validx == nil then return {} end -- no object with this property
      local objects = rawget(validx, prop.value)
      if objects == nil then return {} end -- no object with this property value
      sets[i] = objects
      local size = sizeOf[objects]
      if size < min_sz then
        min_sz = size
        min = i
      end
    end
    -- remove the smallest set from the list and place it in 'min'
    min, sets[min], sets[count] = sets[min], sets[count], nil
    -- select the objects from the minimum set that are also present
    -- in the other sets (i.e. satisfy all other properties)
    for object in pairs(min) do
      for index = 1, count-1 do
        if sets[index][object]==nil then
          goto continue
        end
      end
      found[#found+1] = object
      ::continue::
    end
  end
  return found
end

local Empty = {}
function PropertyIndex:get(name, value)
  local validx = rawget(self.index, name)
  if validx ~= nil then
    return rawget(validx, value) or Empty
  end
  return Empty
end

return PropertyIndex
