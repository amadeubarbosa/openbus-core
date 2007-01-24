require "OOP"

TestCase = createClass()

function TestCase:run(result)
  result:startTestCase(self.name)
  if self.testCase.beforeTestCase then
    self.testCase:beforeTestCase()
  end
  for _, test in pairs(self.tests) do
    if self.testCase.beforeEachTest then
      self.testCase:beforeEachTest()
    end
    test:run(result)
    if self.testCase.afterEachTest then
      self.testCase:afterEachTest()
    end
  end
  if self.testCase.afterTestCase then
    self.testCase:afterTestCase()
  end
  result:stopTestCase()
end
