--
-- verbose.lua
--

local print  = print
local string = string

local verbose = require "loop.debug.Verbose"

module "ftc.verbose"

LOG = verbose {
  groups = {
    {"log"},
    {"open"},
    {"close"},
    {"truncate"},
    {"getPosition"},
    {"setPosition"},
    {"getSize"},
    {"read"},
    {"write"},
    {"OctBytes2Long"},
    all = {
      "log",
      "open",
      "close",
      "truncate",
      "getPosition",
      "setPosition",
      "getSize",
      "read",
      "write",
      "OctBytes2Long"
    },
  },
}
LOG:flag("all", true)

function bytes(str)
  local out = ""
  for x=1, string.len(str) do
    out = out..string.byte(str, x, x).."("..string.gsub(string.sub(str, x, x), "[^%w%p]", "*")..") "
  end --for
  return out
end
