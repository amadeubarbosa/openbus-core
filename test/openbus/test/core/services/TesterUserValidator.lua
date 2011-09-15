-- $Id$

local function validator(name, password)
	if name == "tester" and password == name then
		return true
	end
end

return function() return validator end
