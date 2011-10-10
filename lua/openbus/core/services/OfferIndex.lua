local _G = require "_G"
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local rawget = _G.rawget

local table = require "loop.table"
local memoize = table.memoize

local math = require "math"
local inf = math.huge

local oo = require "openbus.util.oo"
local class = oo.class



local ReturnZero = { __index = function() return 0 end }
local function newOfferSet() return {} end
local function newValueIndex() return memoize(newOfferSet) end



local OfferIndex = class()

function OfferIndex:__init()
	self.sizeOf = setmetatable({}, ReturnZero)
	self.index = memoize(newValueIndex)
end

function OfferIndex:add(offer)
	local index = self.index
	local sizeOf = self.sizeOf
	for _, prop in ipairs(offer.properties) do
		local offers = index[prop.name][prop.value]
		if offers[offer] == nil then
			offers[offer] = true
			sizeOf[offers] = sizeOf[offers]+1
		end
	end
end

function OfferIndex:remove(offer)
	local index = self.index
	local sizeOf = self.sizeOf
	for _, prop in ipairs(offer.properties) do
		local name = prop.name
		local value = prop.value
		local validx = index[name]
		local offers = validx[value]
		local size = sizeOf[offers]
		if size > 1 then
			sizeOf[offers] = size-1
			offers[offer] = nil
		else
			sizeOf[offers] = nil
			validx[value] = nil -- last offer with this property value was removed
			if next(validx) == nil then
				index[name] = nil -- last offer with this property was removed
			end
		end
	end
end

function OfferIndex:find(properties)
	local found = {}
	local count = #properties
	if count > 0 then
		local index = self.index
		local sizeOf = self.sizeOf
		-- collecting all sets of offers with any of these properties
		-- and find the which of these set has less offers.
		local sets = {}
		local min_sz, min = inf
		for i = 1, count do
			local prop = properties[i]
			local validx = rawget(index, prop.name)
			if validx == nil then return {} end -- no offer with this property
			local offers = rawget(validx, prop.value)
			if offers == nil then return {} end -- no offer with this property value
			sets[i] = offers
			local size = sizeOf[offers]
			if size < min_sz then
				min_sz = size
				min = i
			end
		end
		-- remove the smallest set from the list and place it in 'min'
		min, sets[min], sets[count] = sets[min], sets[count], nil
		-- select the offers from the minimum set that are also present
		-- in the other sets (i.e. satisfy all other properties)
		for offer in pairs(min) do
			local exclude
			for index = 1, count-1 do
				exclude = (sets[index][offer]==nil)
			end
			if not exclude then
				found[#found+1] = offer
			end
		end
	end
	return found
end

local Empty = {}
function OfferIndex:get(name, value)
	local validx = rawget(self.index, name)
	if validx ~= nil then
		return rawget(validx, value) or Empty
	end
	return Empty
end

return OfferIndex
