-- uuid.lua
-- support code for uuid library
-- usage lua -luuid ...

local function so(x)
	local SOPATH= os.getenv"LUA_SOPATH" or "./"
	assert(package.loadlib(SOPATH.."l"..x..".so","luaopen_"..x))()
end

so"uuid"
