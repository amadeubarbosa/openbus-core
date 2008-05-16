--
--  tests.lua
--

local Check = require "latt.Check"
local FileGenerator = require "FileGenerator"

require "oil"
require "ftc"

require "config"

local accessKey = "tester"

Suite = {
  TestOPEN = {
    testFileNotFound = function(self)
      print 'testFileNotFound'
      oil.main(function()
        local id = SERVER_TMP_PATH.."/FILE_NOT_FOUND"
        local writable = false
        local size = 20
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
       Check.assertNil(file:open(true))
      end)
    end,
--     testNoPermission = function(self)
--       oil.main(function()
--         local id = SERVER_TMP_PATH.."/NO_PERMISSION"
--         local writable = false
--         local size = 20
--         local file = FileGenerator(id, size)
--         file:chmod("-rw")
--         local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
--         Check.assertNil(file:open(true))
--       end)
--     end,
    testOpen20b = function(self)
      print 'testOpen20b'
      oil.main(function()
        local writable = false
        local size = 20
        local id = SERVER_TMP_PATH.."/20b"
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNotNil(file:open(true))
        Check.assertTrue(file:isOpen())
        Check.assertTrue(file:close())
      end)
    end,
    testWritableANDReadOnlyFALSE = function(self)
      print 'testWritableANDReadOnlyFALSE'
      oil.main(function()
        local writable = false
        local size = 20
        local id = SERVER_TMP_PATH.."/20b"
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
      -- tentado abrir arquivo que não pode ser aberto para escrita
        Check.assertNil(file:open(false))
        Check.assertNil(file:isOpen())
      end)
    end,
  },
  TestCLOSE = {
    testNotOpened = function(self)

      print 'testNotOpened'
      oil.main(function()
        local id = SERVER_TMP_PATH.."/FILE_NOT_FOUND"
        local writable = false
        local size = 20
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNil(file:close())
      end)
    end,
    testSucessOperation = function(self)
      oil.main(function()
        print 'testSucessOperation'
        local writable = false
        local size = 20
        local id = SERVER_TMP_PATH.."/20b"
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNotNil(file:open(true))
        Check.assertNotNil(file:close())
      end)
    end,
  },
  TestTRUNCATE = {
    testReadOnly = function(self)
      oil.main(function()
        print 'testReadOnly'
        local id = SERVER_TMP_PATH.."/20b"
        local writable = true
        local size = 20
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNotNil(file:open(true))
        Check.assertNil(file:truncate(10))
        Check.assertTrue(file:close())
      end)
    end,
    testTruncate = function(self)
      oil.main(function()
        print 'testTruncate'
        local writable = true
        local size = 20
        local id = SERVER_TMP_PATH.."/20b"
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNotNil(file:open(false))
        Check.assertNotNil(file:truncate(10))
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestSETPOSITION = {
    testSetPosition = function(self)
      oil.main(function()
        print 'testSetPosition'
        local id = SERVER_TMP_PATH.."/20b"
        local writable = true
        local size = 20
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNotNil(file:open(false))
        Check.assertNotNil(file:setPosition(10))
        local _, position = file:getPosition()
        Check.assertEquals(position, 10)
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestGETPOSITION = {
    testGetPosition = function(self)
      oil.main(function()
        print 'testGetPosition'
        local id = SERVER_TMP_PATH.."/20b"
        local writable = true
        local size = 20
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNotNil(file:open(false))
        local _, position = file:getPosition()
        Check.assertEquals(position, 0)
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestGETSIZE = {
    testGetSize = function(self)
      oil.main(function()
        print 'testGetSize'
        local id = SERVER_TMP_PATH.."/100b"
        local writable = true
        local size = 100
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNotNil(file:open(false))
        local _, size = file:getSize()
        Check.assertEquals(size, 100)
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestREAD = {
    testRead = function(self)
      oil.main(function()
        print 'testRead'
        local id = SERVER_TMP_PATH.."/10b"
        local writable = true
        local size = 10
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNotNil(file:open(false))
        local status, buffer = file:read(3,0)
        Check.assertEquals(buffer, "TEC")
        local status, buffer = file:read(3,3)
        Check.assertEquals(buffer, "GRA")
        Check.assertTrue(file:close())
      end)
    end,
  },
  TestWRITE = {
    testWrite = function(self)
      oil.main(function()
        print 'testWrite'
        local id = SERVER_TMP_PATH.."/7b"
        local writable = true
        local size = 7
--         fg(id, size)
        local file = ftc(id, writable, size, SERVER_HOST, SERVER_PORT, accessKey)
        Check.assertNotNil(file:open(false))
        Check.assertNotNil(file:write(7, 0, "tecgraf"))
        Check.assertTrue(file:close())
      end)
    end,
  },
}
