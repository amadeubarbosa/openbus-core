local _G = require "_G"
local assert = _G.assert
local select = _G.select

local luaidl = require "luaidl"
local parse = luaidl.parse

local Compiler = require "oil.corba.idl.Compiler"
local options = Compiler().defaults

local function addAllTo(list, ...)
	for i = 1, select("#", ...) do
		list[#list+1] = select(i, ...)
	end
end

local defs = {}
options.incpath = {"idl/legacy","idl"}
addAllTo(defs, assert(parse('#include "fault_tolerance_service.idl"', options)))
addAllTo(defs, assert(parse('#include "access_control_service.idl"', options)))
addAllTo(defs, assert(parse('#include "registry_service.idl"', options)))
return defs
