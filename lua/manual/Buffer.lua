local oo = require "manual.oo"

local Buffer = oo.class{
	identcount = 0,
	identation = "",
	output = table.concat,
}

function Buffer:write(...)
	local base = #self
	if self.linebreak then
		base = base+1
		self[base] = "\n"..string.rep("\t", self.identcount)
		self.linebreak = nil
	end
	for index = 1, select("#", ...) do
--
--if type(select(index, ...)) ~= "string" then error("Ooops! "..type(select(index, ...)).."@"..index) end
--
		self[base+index] = select(index, ...)
	end
end

function Buffer:writeln(...)
	self:write(...)
	self.linebreak = true
end

function Buffer:ident(shift)
	self.identcount = self.identcount+shift
	self.identation = string.rep("\t", self.identcount)
end

return Buffer
