local loader = require "manual.loader"
local html = require "manual.html"

local input, output
input, output, loader.language = ...

local manual, types = loader.load(assert(loadfile(input))())
local file = assert(io.open(output, "w"))
file:write(html.output(manual, types))
file:close()
