--
--  tests.lua
--

local Check = require "latt.Check"
local fg    = require "ftc.tests.FileGenerator"

require "oil"

local rfc = require "ftc"

local host = "localhost"
local port = 40120
local accessKey = "Key"

Suite = {
  TestOPEN = {
    testFileNotFound = function(self)
      oil.main(function()
        local id = "/tmp/FILE_NOT_FOUND"
        local writable = false
        local size = 20
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNil(file:open(true))
      end)
    end,
    testNoPermission = function(self)
      oil.main(function()
        local id = "/tmp/NO_PERMISSION"
        local writable = false
        local size = 20
        local file = fg(id, size)
        file:chmod("-rw")
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNil(file:open(true))
      end)
    end,
    testOpen20b = function(self)
      oil.main(function()
        local writable = false
        local size = 20
        local id = "/tmp/20b"
        fg(id, size)
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNotNil(file:open(true))
        Check.assertTrue(file:isOpen())
        Check.assertTrue(file:close())
      end)
    end,
    testWritableANDReadOnlyFALSE = function(self)
      oil.main(function()
        local writable = false
        local size = 20
        local id = "/tmp/20b"
        local file = rfc(id, writable, size, host, port, accessKey)
      -- tentado abrir arquivo que não pode ser aberto para escrita
        Check.assertNil(file:open(false))
        Check.assertNil(file:isOpen())
      end)
    end,
  },
  TestCLOSE = {
    testNotOpened = function(self)
      oil.main(function()
        local id = "/tmp/FILE_NOT_FOUND"
        local writable = false
        local size = 20
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNil(file:close())
      end)
    end,
    testSucessOperation = function(self)
      oil.main(function()
        local writable = false
        local size = 20
        local id = "/tmp/20b"
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNotNil(file:open(true))
        Check.assertNotNil(file:close())
      end)
    end,
  },
  TestTRUNCATE = {
    testReadOnly = function(self)
      oil.main(function()
        local id = "/tmp/20b"
        local writable = true
        local size = 20
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNotNil(file:open(true))
        Check.assertNil(file:truncate(10))
        Check.assertTrue(file:close())
      end)
    end,
    testTruncate = function(self)
      oil.main(function()
        local writable = true
        local size = 20
        local id = "/tmp/20b"
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNotNil(file:open(false))
        Check.assertNotNil(file:truncate(10))
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestSETPOSITION = {
    testOperation = function(self)
      oil.main(function()
        local id = "/tmp/20b"
        local writable = true
        local size = 20
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNotNil(file:open(false))
        Check.assertNotNil(file:setPosition(10))
        local _, position = file:getPosition()
        Check.assertEquals(position, 10)
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestGETPOSITION = {
    testOperation = function(self)
      oil.main(function()
        local id = "/tmp/20b"
        local writable = true
        local size = 20
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNotNil(file:open(false))
        local _, position = file:getPosition()
        Check.assertEquals(position, 0)
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestGETSIZE = {
    testOperation = function(self)
      oil.main(function()
        local id = "/tmp/100b"
        local writable = true
        local size = 100
        fg(id, size)
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNotNil(file:open(false))
        local _, size = file:getSize()
        Check.assertEquals(size, 100)
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestREAD = {
    testOperation = function(self)
      oil.main(function()
        local id = "/tmp/10b"
        local writable = true
        local size = 10
        fg(id, size)
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNotNil(file:open(false))
        local status, buffer = file:read(3,0)
        Check.assertEquals(buffer, "***")
        local status, buffer = file:read(3,3)
        Check.assertEquals(buffer, "***")
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestWRITE = {
    testOperation = function(self)
      oil.main(function()
        local id = "/tmp/7b"
        local writable = true
        local size = 7
        fg(id, size)
        local file = rfc(id, writable, size, host, port, accessKey)
        Check.assertNotNil(file:open(false))
        Check.assertNotNil(file:write("ricardo", 7, 0))
        Check.assertTrue(file:close())
      end)
    end,
  },
}
