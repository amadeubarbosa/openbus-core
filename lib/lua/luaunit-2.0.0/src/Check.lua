require "OOP"

Check = createClass()

function Check.assertError(f, ...)
  local success = pcall(f, unpack(arg))
  if success then
    error()
  end
end

function Check.assertEquals(expected, actual)
  if expected ~= actual then
    error()
  end
end

function Check.assertNotEquals(expected, actual)
  if expected == actual then
    error("The expected value ("..expected..") shouldn't be equal the actual value ("..actual..").")
  end
end

function Check.assertTrue(condition)
  if condition == false then
    error("Condition should be true.", 2)
  end
end

function Check.assertFalse(condition)
  if condition == true then
    error("Condition should be false.", 2)
  end
end

function Check.assertNil(variable)
  if variable ~= nil then
    error()
  end
end

function Check.assertNotNil(variable)
  if variable == nil then
    error()
  end
end
