--
--  runFileGenerator.lua
--

local fg = require "ftc.test.FileGenerator"

if ( not (arg[1] and arg[2])) then
  print("Use:lua runFileGenerator <sizeOfFile> <filePath>")
end

local file = fg(arg[2], arg[1])
