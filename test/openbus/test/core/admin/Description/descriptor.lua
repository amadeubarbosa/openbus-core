local string = require "string"
local lfs = require "lfs"
local oil = require "oil"
local hash = require "lce.hash"
local utils = require "openbus.util.server"

require "openbus.test.configs"

local temp_dir = os.getenv("OPENBUS_TEMP") or "certificates"
local base_dir = os.getenv("OPENBUS_CORE_TEST").."/openbus/test/core/admin/Description"
local import_dir = base_dir.."/import"
local export_dir = base_dir.."/export"
local cases = {
	quiet_true = true,
	quiet_false = false,
	legacy = true,
	compact = true,
}
local replaces = {
	CERTIFICATE_DEFAULT_DIR = temp_dir,
	CERTIFICATE_MD5_HASH = string.gsub(hash.md5(assert(utils.readfrom(syscrt))), ".",
	                                   function (char)
	                                   	return string.format("%.2x", string.byte(char))
	                                   end),
}

local function same(expected_path, actual_path)
	local expected = utils.readfrom(expected_path):gsub("<([^>]+)>", replaces)
	local actual, errmsg = utils.readfrom(actual_path)
	---[=[ Use the code below to update the expected files when the output format changes
	if actual ~= expected then
		os.execute("diff -ub "..expected_path.." "..actual_path)
		io.write("\nReplace? ")
		if string.match(io.read(), "^[Yy]") then
			oil.writeto(expected_path, actual, "wb")
		end
	end
	--[==[--]=]
	assert(actual, errmsg)
	assert(actual == expected)
	--]==]
end
for file in lfs.dir(import_dir) do
	for mode, quiet in pairs(cases) do
		if string.match(file, "%.lua$") then
			local input_path = import_dir.."/"..file
			local output_path = temp_dir.."/descriptor.lua"
			local expected_path = export_dir.."/"..mode.."_"..file
			local parsed = newdesc()
			parsed.quiet = quiet
			parsed:import(input_path)
			parsed:export(output_path, temp_dir, mode)
			same(expected_path, output_path)
			local recovered = newdesc()
			if mode == "compact" then
				recovered.quiet = true
			end
			recovered:import(output_path)
			recovered:export(output_path, temp_dir, mode)
			same(expected_path, output_path)
		end
	end
end
