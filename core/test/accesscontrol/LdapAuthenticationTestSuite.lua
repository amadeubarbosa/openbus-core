--
-- Testa o funcionamento do lualdap.
-- 
-- $Id$
--
require "lualdap"
require "oil"
local Check = require "latt.Check"

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      -- servidor ldap
      self.hostname = "ldap-teste"
      self.port = ":389"
      self.SSLPort = ":636"
      self.user = "cn=teste,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=br"
      self.password = "teste"
    end,
    
    testValidConnection = function(self)
      local host = self.hostname .. self.port
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, self.user, self.password, false)
      Check.assertTrue(success)
      Check.assertNotNil(connection)
      connection:close()
    end,

    testInvalidHost = function(self)
      local host = "invalid" .. self.port
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, self.user, self.password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Can't contact LDAP server", errorMessage)
    end,

    testInvalidUser = function(self)
      local host = self.hostname .. self.port
      local user = "unknown"
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, user, self.password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid DN syntax", errorMessage)
    end,

    testInvalidUser2 = function(self)
      local host = self.hostname .. self.port
      local user = "cn=unknown,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=br"
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, user, self.password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidUser3 = function(self)
      local host = self.hostname .. self.port
      -- incluindo dc=com
      local user = "cn=teste,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=com,dc=br"
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, user, self.password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidPassword = function(self)
      local host = self.hostname .. self.port
      local password = "invalid"
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, self.user, password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testBlankPassword = function(self)
      local host = self.hostname .. self.port
      local password = ""
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, self.user, password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

    testNilPassword = function(self)
      local host = self.hostname .. self.port
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, self.user, nil, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

    testValidConnectionSSL = function(self)
      local host = self.hostname .. self.SSLPort
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, self.user, self.password, true)
      Check.assertTrue(success)
      Check.assertNotNil(connection)
      connection:close()
    end,

    testInvalidUserSSL = function(self)
      local host = self.hostname .. self.SSLPort
      local user = "unknown"
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, user, self.password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid DN syntax", errorMessage)
    end,

    testInvalidUser2SSL = function(self)
      local host = self.hostname .. self.SSLPort
      local user = "cn=unknown,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=br"
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, user, self.password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidUser3SSL = function(self)
      local host = self.hostname .. self.SSLPort
      -- incluindo dc=com
      local user = "cn=teste,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=com,dc=br"
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, user, self.password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidPassword = function(self)
      local host = self.hostname .. self.SSLPort
      local password = "invalid"
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, self.user, password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testBlankPassword = function(self)
      local host = self.hostname .. self.SSLPort
      local password = ""
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, self.user, password, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

    testNilPassword = function(self)
      local host = self.hostname .. self.SSLPort
      local success, connection, errorMessage = oil.pcall(lualdap.open_simple, host, self.user, nil, false)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

  }
}

