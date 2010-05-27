

messages = {
  { name = "admLogin",
    msg = "Login do administrador",
    type = "string",
    value = "",
  },
}

configure_action = function(answers, path, util)
  if answers.admLogin == "" then
    print "[ERRO] Login do administrador não foi informado"
    return false
  end

  local acsConfFile = path.."/data/conf/AccessControlServerConfiguration.lua"
  assert(loadfile(acsConfFile))()

  hostName = AccessControlServerConfiguration.hostName
  hostPort = AccessControlServerConfiguration.hostPort

  return os.execute(
      path .. "/specs/shell/subscribe-services.sh " .. answers.admLogin
      .. " " .. hostName .. " " .. hostPort .. " " .. path
      )
end
