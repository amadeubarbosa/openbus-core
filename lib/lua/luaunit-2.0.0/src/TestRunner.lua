require "OOP"

require "Test"
require "TestCase"
require "TestSuite"

require "ConsoleResultViewer"

if #arg ~= 1 then
  io.stderr:write("Use: lua TestRunner.lua <test_suite_file_name>\n")
  os.exit(1)
end

dofile(arg[1])

local testCases = {}
for testCaseName, testCase in pairs(Suite) do
  if (string.sub(testCaseName, 1, 4) == "Test") and (not ReservedTypes[testCaseName]) and (type(testCase) == "table" )then
    local tests = {}
      for testName, test in pairs(testCase) do
        if (string.sub(testName, 1, 4) == "test") and (type(test) == "function") then
          table.insert(tests, Test:new{name = testName, test = test, testCase = testCase})
        end
      end
      table.insert(testCases, TestCase:new{name = testCaseName, testCase = testCase, tests = tests,})
  end
end

local suite = TestSuite:new{
  name = Suite.name,
  testCases = testCases,
}
local result = suite:run()
local viewer = ConsoleResultViewer:new{
  result = result
}
viewer:print()
