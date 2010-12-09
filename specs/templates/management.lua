

messages = {
  { name = "admLogin",
    msg = "Login do administrador",
    type = "string",
    value = "",
  },
  { name = "test",
    msg = "Voce deseja cadastrar os testes ?",
    type = "string",
    value = "nao",
  },
}

configure_action = function(answers, path, util)
  if answers.admLogin == "" then
    print "[ERRO] Login do administrador não foi informado"
    return false
  end

  local runTests = string.upper(answers.test):find("SIM") or "true" and ""

  local acsConfFile = path.."/data/conf/AccessControlServerConfiguration.lua"
  assert(loadfile(acsConfFile))()

  local hostName = AccessControlServerConfiguration.hostName
  local hostPort = AccessControlServerConfiguration.hostPort

  return os.execute(string.format(
      "%s/specs/shell/subscribe-services.sh %s %s %s %s %s", path,
      answers.admLogin, hostName, hostPort, path, runTests))
end
