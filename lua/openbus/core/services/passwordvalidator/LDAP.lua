-- $Id$
-- LDAP password validator
-- Configuration options:
--   ldap_servers  : table with URLs of the LDAP servers to be contacted in the
--                   form 'ldap[s]://<host>:<port>. Required.
--   ldap_patterns : table with patterns to form distinguised names (DN) by 
--                   replacing %U with the entity name. Default is {"%U"}
--   ldap_timeout  : timeout for each LDAP access (in seconds). Default is no
--                   timeout.
--   ldap_cleartext: flag to allow passing password as clear text to the LDAP
--                   server that refuses TLS or does not support SSL. Default is
--                   'false'.

local _G = require "_G"
local ipairs = _G.ipairs
local tostring = _G.tostring
local type = _G.type

local array = require "table"
local concat = array.concat

local lualdap = require "lualdap"
local openldap = lualdap.open_simple

local msg = require "openbus.core.services.messages"

return function(configs)
  -- configuration consistence checks
  local servers = configs.ldap_servers
  if type(servers) ~= "table" or #servers == 0 then
    return nil, msg.LdapNoServers
  end
  local patterns = configs.ldap_patterns or { "%U" }
  if type(patterns) ~= "table" or #patterns == 0 then
    return nil, msg.LdapNoDistinguishedNamePattern
  end
  local timeout = configs.ldap_timeout
  if timeout ~= nil and type(timeout) ~= "number" then
    return nil, msg.LdapBadTimeout:tag{value=timeout,type=type(timeout)}
  end
  local cleartext = configs.ldap_cleartext
  -- collect server urls
  local urls = {}
  for _, url in ipairs(servers) do
    if not url:match("^ldaps?://") then
      url = "ldap://"..url
    end
    urls[#urls+1] = url
  end
  -- validate function to be used in runtime
  return function(entity, password)
    -- avoid blank password because this may be allowed as an anonymous bind
    local blankpatt ="^[%s%c%z]*$"
    if type(entity) ~= "string" or entity:match(blankpatt) or
       type(password) ~= "string" or password:match(blankpatt) then
      return nil, msg.LdapInvalidNameOrPassword
    end
    local errmsg = {}
    for _, url in ipairs(urls) do
      for _, pattern in ipairs(patterns) do
        local dn = pattern:gsub("%%U",entity)
        local conn, err
        -- if the url indicates LDAP raw protocol, we try use LDAP+StartTLS
        if url:match("^ldap://") then
          conn, err = openldap(url, dn, password, true, timeout)
        end
        -- if the server rejects LDAP+StartTLS or if url already indicates LDAPS
        if (not conn and cleartext) or url:match("^ldaps://") then
          conn, err = openldap(url, dn, password, false, timeout)
        end
        if conn ~= nil then
          conn:close()
          return true
        end
        errmsg[#errmsg+1] = msg.LdapAccessAttemptFailed:tag{
          user = dn,
          server = url,
          errmsg = tostring(err),
        }
      end
    end
    return nil, msg.LdapAccessFailed:tag{errmsg=concat(errmsg,"; ")}
  end
end
