local _G = require "_G"
local pcall = _G.pcall

local lualdap = require "lualdap"
local Check = require "latt.Check"

-- Informações Gerais ---------------------------------------------------------
-- Esse teste foi criado para ser utilizado com servidores OpenLDAP.
-- Não experimentamos contra servidores ActiveDirectory, provavelmente o AD
-- envia mensagens de erro diferentes das que o servidor OpenLDAP emite. Isso
-- causará falha de vários desses testes, pois comparamos as mensagens de erro.

-- Configurações --------------------------------------------------------------
local url = "ldap://ldap-teste:389"
local urlSSL = "ldaps://ldap-teste:636"
local pattern = "cn=%U,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=br"
local name = "teste"
local password = "teste"
local timeout = 5

local scsutils = require ("scs.core.utils")()
local props = {}
scsutils:readProperties(props, "test.properties")
scsutils = nil

url = props:getTagOrDefault("ldapUrl", url)
urlSSL = props:getTagOrDefault("ldapUrlSSL", urlSSL)
pattern = props:getTagOrDefault("ldap-pattern", pattern)
name = props:getTagOrDefault("ldapUser", name)
password = props:getTagOrDefault("ldapPassword", password)
timeout = tonumber(props:getTagOrDefault("ldapTimeout", timeout))

local user = pattern:gsub("%%U",name)

-- Casos de Teste -------------------------------------------------------------
Suite = {
  Test1 = {
    beforeTestCase = function(self)
      -- servidor ldap
      self.url = url
      self.urlSSL = urlSSL
      self.user = user
      self.password = password
    end,

    testValidConnection = function(self)
      local url = self.url
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNotNil(connection)
      connection:close()
    end,

    testInvalidUrlSyntax = function(self)
      local url = "invalid:666" -- missing '<protocol>://' prefix
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("LuaLDAP: Error connecting to server (Bad parameter to an ldap routine)", errorMessage)
    end,

    testInvalidHost = function(self)
      local url = "ldap://invalid"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Can't contact LDAP server", errorMessage)
    end,
    
    testInvalidHost2 = function(self)
      local url = "ldap://invalid:123"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Can't contact LDAP server", errorMessage)
    end,

    testInvalidUser = function(self)
      local url = self.url
      local user = "unknown"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid DN syntax", errorMessage)
    end,

    testInvalidUser2 = function(self)
      local url = self.url
      local user = "cn=unknown,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=br"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidUser3 = function(self)
      local url = self.url
      -- incluindo dc=com
      local user = "cn=teste,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=com,dc=br"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidPassword = function(self)
      local url = self.url
      local password = "invalid"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testBlankPassword = function(self)
      local url = self.url
      local password = ""
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

    testNilPassword = function(self)
      local url = self.url
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, nil, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

    testValidConnectionTLS = function(self)
      local url = self.url
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, self.password, true, timeout)
      Check.assertTrue(success)
      Check.assertNotNil(connection)
      connection:close()
    end,

    testInvalidUserTLS = function(self)
      local url = self.url
      local user = "unknown"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, user, self.password, true, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid DN syntax", errorMessage)
    end,

    testInvalidUser2TLS = function(self)
      local url = self.url
      local user = "cn=unknown,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=br"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, user, self.password, true, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidUser3TLS = function(self)
      local url = self.url
      -- incluindo dc=com
      local user = "cn=teste,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=com,dc=br"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, user, self.password, true, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidPasswordTLS = function(self)
      local url = self.url
      local password = "invalid"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, password, true, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testBlankPasswordTLS = function(self)
      local url = self.url
      local password = ""
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, password, true, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

    testNilPasswordTLS = function(self)
      local url = self.url
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, nil, true, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

    testValidConnectionSSL = function(self)
      local url = self.urlSSL
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNotNil(connection)
      connection:close()
    end,
    
    testInvalidSettingSSL = function(self)
      -- we cannot try to connect using a ldaps:// and setting StartTLS flag as true
      local url = self.urlSSL
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, self.password, true, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Operations error", errorMessage)
    end,

    testInvalidUserSSL = function(self)
      local url = self.urlSSL
      local user = "unknown"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid DN syntax", errorMessage)
    end,

    testInvalidUser2SSL = function(self)
      local url = self.urlSSL
      local user = "cn=unknown,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=br"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidUser3SSL = function(self)
      local url = self.urlSSL
      -- incluindo dc=com
      local user = "cn=teste,ou=usuarios,dc=tecgraf,dc=puc-rio,dc=com,dc=br"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, user, self.password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testInvalidPasswordSSL = function(self)
      local url = self.urlSSL
      local password = "invalid"
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Invalid credentials", errorMessage)
    end,

    testBlankPasswordSSL = function(self)
      local url = self.urlSSL
      local password = ""
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, password, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

    testNilPasswordSSL = function(self)
      local url = self.urlSSL
      local success, connection, errorMessage = pcall(lualdap.open_simple, url, self.user, nil, false, timeout)
      Check.assertTrue(success)
      Check.assertNil(connection)
      Check.assertEquals("Server is unwilling to perform", errorMessage)
    end,

  }
}

