local Viewer = require "loop.debug.Viewer"
local oo = require "manual.oo"
local Buffer = require "manual.Buffer"
local loader = require "manual.loader"
local i18n = require "manual.i18n"

local CallableFields = {"parameters", "results"}

local HTMLBuffer = oo.class({}, Buffer)

function HTMLBuffer:__new(...)
	local self = oo.rawnew(self, ...)
	self.viewer = Viewer{
		output = self,
		linebreak = false,
		noindices = true,
		nolabels = true,
		metaonly = true,
	}
	return self
end

function HTMLBuffer:value(...)
	self:write("<code>")
	self.viewer:write(...)
	self:write("</code>")
end

function HTMLBuffer:code(...)
	self:write("<code>", ...)
	self:write("</code>")
end

function HTMLBuffer:emphasis(...)
	self:write("<em>", ...)
	self:write("</em>")
end

function HTMLBuffer:paragraph(text)
	local function replaceRef(id)
		local desc = self.types[id]
		if desc == nil then
			return '<code>'..id..'</code>'
		else
			return '<a href=#'..id..'>'..(desc.title or desc.name)..'</a>'
		end
	end
	local extra = text:match("^%s+")
	if extra ~= nil then
		text = text:gsub("\n"..extra, "\n")
		           :gsub("^"..extra, "")
		           :gsub("%s+$", "")
	end
	self:write((text:gsub("\n\n", "</p>\n"..self.identation.."<p>")
	                :gsub("\n", "\n"..self.identation)
	                :gsub("<#([_%a][_%w]*)>", replaceRef)))
end

function HTMLBuffer:type(id, label, anchor)
	local desc = self.types[id]
	local ref
	if desc ~= nil then
		label, ref = label or desc.title, id
	end
	label = label or id
	local link = ref ~= nil or anchor ~= nil
	if link then
		self:write('<a')
		if anchor ~= nil then
			self:write(' name="',anchor,'"')
		end
		if ref ~= nil then
			self:write(' href="#',ref,'"')
		end
		self:write('>')
	end
	self:write(label)
	if link then
		self:write('</a>')
	end
end



local summary
local contents
local entries

local TitleOfField = {
	parameters = "Parameter",
	results = "Returned value",
}
local ClassOfField = {
	parameters = "Parameters",
	results = "Values Returned",
}

local function method(desc)
	contents:writeln('<table>')
	contents:ident(1)
	local lang = desc.language or loader.language or "en"
	local msg = assert(i18n[lang], "output language not supported")
	for _, field in ipairs(CallableFields) do
		local list = desc[field]
		if list ~= nil then
			contents:writeln('<tr>')
			contents:ident(1)
			contents:writeln('<th colspan=4 align=left>',msg.CallableValueHeader[field],'</th>')
			contents:ident(-1)
			contents:writeln('</tr>')
			for index, arg in ipairs(list) do
				contents:writeln('<tr>')
				contents:ident(1)
				contents:writeln('<td><code>',arg.name,'</code></td>')
				contents:write('<td><code>=</code></td><td><code>')
				if type(arg.type) == "table" then
					for index, info in ipairs(arg.type) do
						if index > 1 then
							contents:write('|')
						end
						contents:type(info.type, info.type)
					end
				elseif arg.type ~= nil then
					contents:type(arg.type, arg.type)
				end
				contents:writeln('</code></td>')
				contents:writeln('<td>',arg.title or "",'</td>')
				contents:ident(-1)
				contents:writeln('</tr>')
			end
		end
	end
	contents:ident(-1)
	contents:writeln('</table>')
	contents:write('<p>')
	desc:writeDesc(contents)
	contents:writeln('</p>')
	for _, field in ipairs(CallableFields) do
		local list = desc[field]
		if list ~= nil then
			for _, arg in ipairs(list) do
				local msg = assert(i18n[arg.language or lang], "output language not supported")
				contents:write('<p>',msg.CallableValueLabel[field],' ')
				arg:writeDesc(contents)
				contents:writeln('</p>')
			end
		end
	end
end

local function definition(desc)
	summary:writeln('<li><a href="#',desc.id,'">',desc.title or desc.name,'</a></li>')
	contents:writeln('<h2><a name="',desc.id,'">',desc.title or desc.name,'</a></h2>')
	if desc.type == "table" then
		contents:write('<p>')
		desc:writeDesc(contents)
		contents:writeln('</p>')
		if desc.fields ~= nil then
			contents:writeln('<dl>')
			contents:ident(1)
			for _, desc in ipairs(desc.fields) do
				entries[#entries+1] = desc
				contents:write('<dt><code>')
				desc:writeId(contents, desc.id)
				contents:writeln('</code></dt>')
				contents:writeln('<dd>')
				contents:ident(1)
				if desc.type == "function" or desc.type == "method" then
					method(desc)
				else
					contents:write('<p>')
					desc:writeDesc(contents)
					contents:writeln('</p>')
				end
				contents:ident(-1)
				contents:writeln('</dd>')
			end
			contents:ident(-1)
			contents:writeln('</dl>')
		end
	elseif desc.type == "function" then
		entries[#entries+1] = desc
		contents:write('<h3><code>')
		desc:writeId(contents)
		contents:writeln('</code></h3>')
		method(desc)
	else
		contents:write('<p>')
		desc:writeDesc(contents)
		contents:writeln('</p>')
	end
end

local function result(root, types)
	summary.types = types
	contents.types = types
	summary:writeln('<h1>',root.title or root.name,'</h1>')
	contents:write('<p>')
	root:writeDesc(summary)
	contents:writeln('</p>')
	summary:writeln('<h2>Summary</h2>')
	summary:writeln('<ol>')
	summary:ident(1)
	for index, desc in ipairs(root.fields) do
		definition(desc)
	end
	summary:writeln('<li><a href="#(index)">API Index</a></li>')
	summary:ident(-1)
	summary:writeln('</ol>')
	contents:writeln('<h2><a name=(index)>API Index</a></h2>')
	contents:writeln('<table>')
	contents:ident(1)
	table.sort(entries, function(one, other) return one.id < other.id end)
	for _, desc in pairs(entries) do
		if desc.name ~= nil then
			contents:writeln('<tr>')
			contents:ident(1)
			contents:writeln('<td><code><a href=#',desc.id,'>',desc.id,'</a><code></td>')
			contents:writeln('<td>',desc.title or '','</td>')
			contents:ident(-1)
			contents:writeln('</tr>')
		end
	end
	contents:ident(-1)
	contents:writeln('</table>')
	return summary:output().."\n"..contents:output()
end



local module = {}

function module.output(manual, types)
	summary = HTMLBuffer()
	contents = HTMLBuffer()
	entries = {}
	return [[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<title>Lua Man Demo</title>
</head>

<body>

]]..result(manual, types)..[[

</body>

</html>]]
end

return module
