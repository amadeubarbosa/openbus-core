-- $Id$

local _G = require "_G"
local ipairs = _G.ipairs
local tostring = _G.tostring

local array = require "table"
local concat = array.concat

local lualdap = require "lualdap"
local openldap = lualdap.open_simple

local msg = require "openbus.core.services.messages"

return function(configs)
  -- configuration consistence checks
  local urls = {}
  if not configs.ldap_servers or type(configs.ldap_servers) ~= "table" or 
    (type(configs.ldap_servers) == "table" and #configs.ldap_servers == 0) then
    return nil, msg.LdapNoServers
  end
  for _, url in ipairs(configs.ldap_servers) do
    if not url:match("^ldap://") and not url:match("^ldaps://") then
      url = "ldap://"..url
    end
    urls[#urls+1] = url
  end
  local timeout = nil
  if type(configs.ldap_timeout) == "number" then
    timeout = configs.ldap_timeout
  end
  local patterns = configs.ldap_patterns or { "" }
  if type(patterns) ~= "table" then
    return nil, msg.LdapBadPatternSpec:tag{type=type(patterns)}
  end
  -- validate function to be used in runtime
  return function(name, password)
    local errmsg = {}
    for _, url in ipairs(urls) do
      for _, pattern in ipairs(patterns) do
        local dn = pattern:gsub("%%U",name)
        local conn, err
        -- if the url indicates LDAP raw protocol, we try use LDAP+StartTLS
        if url:match("^ldap://") then
          conn, err = lualdap.open_simple(url, dn, password, true, timeout)
        end
        -- if url already indicates LDAPS or if the server rejects LDAP+StartTLS
        if url:match("^ldaps://") or not conn then
          conn, err = lualdap.open_simple(url, dn, password, false, timeout)
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
