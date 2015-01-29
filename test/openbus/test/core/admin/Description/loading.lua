local utils = require "openbus.util.server"
local readfrom = utils.readfrom
local temp_dir = os.getenv("OPENBUS_TEMP") or "certificates"
local base_dir = os.getenv("OPENBUS_CORE_TEST").."/openbus/test/core/admin/Description"

require "openbus.test.configs"

login(busref, admin, admpsw, domain)

-- download configs
local downloaded = newdesc()
downloaded:download()

-- remove all configs
downloaded:revert()

-- get all configs left
local empty = newdesc()
empty:download()

-- restore configs
downloaded:upload()

-- check the are no configs left
empty:export(temp_dir.."/empty.lua", temp_dir)
assert(readfrom(temp_dir.."/empty.lua", "r") == "")
