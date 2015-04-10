local oo = require "manual.oo"
local i18n = require "manual.i18n"



local module = {}



local function validId(id)
	return id ~= nil and id:match("^[%a_]+[%w_]*$") ~= nil
end

local count = 0
local function newId(id)
	count = count + 1
	return "(doc"..count..")"
end

local function compareNames(one, other)
	return one.name < other.name
end

local function compareTitles(one, other)
	one = one.title or one.name
	other = other.title or other.name
	return one < other
end

local function Sorted(map, comp)
	local list = {}
	for name, desc in pairs(map) do
		if type(name) == "string" then
			desc.name = name
			list[#list+1] = desc
		end
	end
	table.sort(list, comp or compareNames)
	local base = #map
	for index, desc in ipairs(list) do
		map[base+index] = desc
	end
	for index, desc in ipairs(map) do
		desc.index = index
	end
end

local Node = oo.class()

local function Varargs(list, prefix, scope)
	if list ~= nil then
		for index, item in ipairs(list) do
			if item.name == nil then
				item.name = prefix..index
			end
			item.kind = prefix
			Node(item, scope)
		end
		return list
	end
end

local function Callable(desc)
	desc.parameters = Varargs(desc.parameters, "arg", desc)
	desc.results = Varargs(desc.results, "ret", desc)
end

function Node:__new(desc, scope)
	oo.rawnew(self, desc)
	desc.scope = scope
	if scope == nil then
		desc.id = desc.name or newId()
	elseif desc.type == "method" then
		desc.id = scope.id..":"..desc.name
	elseif validId(scope.id) then
		desc.id = scope.id.."."..desc.name
	else
		desc.id = desc.name
	end
	if desc.type == "function" or desc.type == "method" then
		Callable(desc)
	end
	return desc
end

local function writeVarargs(out, list)
	local count = 0
	for index, value in ipairs(list) do
		local optional = value.eventual ~= nil or value.default ~= nil
		if optional then
			if index > 1 then
				out:write(" [")
			else
				out:write("[")
			end
			count = count+1
		else
			out:write(string.rep("]", count))
			count = 0
		end
		if index > 1 then
			out:write(", ")
		end
		out:type(value.type, value.name)
	end
	if count > 0 then
		out:write(string.rep("]", count))
	end
end

function Node:writeId(out, ...)
	local callable = (self.type == "method" or self.type == "function")
	if callable and self.results ~= nil and #self.results > 0 then
		writeVarargs(out, self.results)
		out:write(' = ')
	end
	out:type(self.type, self.id, ...)
	if callable then
		out:write('(')
		if self.parameters ~= nil then
			writeVarargs(out, self.parameters)
		end
		out:write(')')
	end
end

function Node:writeDesc(out)
	local lang = self.language or module.language or "en"
	local i18n = assert(i18n[lang], "output language not supported")
	local described
	if self.name == "..." or validId(self.name) then
		out:code(self.name)
		if type(self.type) == "table" then
			for index, info in ipairs(self.type) do
				if index == 1 then
					out:write(" ",#self.type == 2 and i18n.IsEitherA or i18n.IsA, " ")
				else
					out:write("; ",i18n.OrA," ")
				end
				out:type(info.type)
				if info.description ~= nil then
					out:write(" ",i18n.That," ")
					out:paragraph(info.description)
					described = true
				end
			end
			out:write(".")
		elseif self.type ~= nil then
			out:write(" ",i18n.IsA," ")
			out:type(self.type)
			if self.description == nil then
				out:write(".")
			else
				out:write(" ",i18n.That)
			end
		elseif self.description == nil then
			out:write(".")
		end
	end
	if self.description ~= nil then
		out:write(" ")
		out:paragraph(self.description)
	elseif not described and self.title ~= nil then
		out:emphasis(" ("..self.title..")")
	end
	if self.default ~= nil and self.kind == "arg" then
		out:writeln()
		out:write(i18n.TheDefaultValueIs," <code>")
		out:value(self.default)
		out:write("</code>.")
	end
	if self.eventual ~= nil then
		out:writeln()
		out:write(self.kind == "arg" and i18n.WhenAbsent or i18n.ItIsAbsentWhen," ")
		out:paragraph(self.eventual)
	end
end

local DefinitionTypes = {
	["table"] = true,
	["function"] = true,
}

local function Definition(desc, types)
	if desc.type ~= nil and DefinitionTypes[desc.type] == nil then
		error("illegal definition type, got '"..tostring(desc.type).."'")
	end
	Node(desc)
	types[desc.id] = desc
	if (desc.type ~= nil and desc.type ~= "table") or desc.name ~= nil then
		assert(validId(desc.name),
			"illegal definition name, got '"..tostring(desc.name).."'")
		desc.id = desc.name
	end
	if desc.type == "table" then
		Sorted(desc.fields)
		for index, field in ipairs(desc.fields) do
			assert(validId(field.name),
				"illegal field name, got '"..tostring(desc.name).."'")
			Node(field, desc)
			types[field.id] = field
		end
	end
end

local function Root(desc)
	local types = {}
	Node(desc)
	Sorted(desc.fields, compareTitles)
	for index, field in ipairs(desc.fields) do
		Definition(field, types)
	end
	return types
end



function module.load(root)
	local types = Root(root)
	return root, types
end

return module
