require "OOP"

TestResult = createClass()

function TestResult:startTestSuite(suiteName)
  self.suiteName = suiteName
  self.testCounter = 0
  self.failureCounter = 0
  self.failures = {}
  self.startTime = os.time()
end

function TestResult:stopTestSuite()
  self.stopTime = os.time()
end

function TestResult:startTestCase(testCaseName)
  self.currentTestCaseName = testCaseName
end

function TestResult:stopTestCase()
  self.currentTestCaseName = nil
end

function TestResult:startTest(testName)
  self.currentTestName = testName
end

function TestResult:stopTest(errorMessage)
  self.testCounter = self.testCounter + 1
  if errorMessage then
    self.failureCounter = self.failureCounter + 1
    table.insert(self.failures, {testCaseName = self.currentTestCaseName, testName = self.currentTestName, errorMessage = errorMessage, })
  end
  self.currentTestName = nil
end
