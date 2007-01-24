require "OOP"

require "ReservedTypes"

require "TestResult"

TestSuite = createClass()

function TestSuite:run()
  local result = TestResult:new{testSuiteName = self.name}
  result:startTestSuite(self.name)
  for _, testCase in ipairs(self.testCases) do
    testCase:run(result)
  end
  result:stopTestSuite()
  return result
end
