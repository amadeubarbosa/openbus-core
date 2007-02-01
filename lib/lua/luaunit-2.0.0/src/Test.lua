require "OOP"

Test = createClass()

function Test:run(result)
  result:startTest(self.name)
  local _, errorMessage = pcall(self.test, self.testCase)
  result:stopTest(errorMessage)
end
