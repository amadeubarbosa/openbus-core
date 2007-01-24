require "OOP"

Test = createClass()

function Test.errorHandler(errorMessage)
  return debug.traceback(errorMessage, 2)
end

function Test:run(result)
  result:startTest(self.name)
  local _, errorMessage = pcall(self.test, self.testCase)
  result:stopTest(errorMessage)
end
