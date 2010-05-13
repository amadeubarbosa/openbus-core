

messages = {
}

configure_action = function(answers, path, util)
  local installPath =  path
  local openSSLGenerate = " ../shell/openssl-generate.ksh -n "
  -- Criando chaves dos servi�os b�sicos.
  os.execute(
      "cd " .. installPath .. "/specs/management;" .. 
      openSSLGenerate .. "AccessControlService;" ..
      openSSLGenerate .. "RegistryService;" ..
      openSSLGenerate .. "SessionService;" ..
      openSSLGenerate .. "ACSMonitor;" ..
      openSSLGenerate .. "RGSMonitor;"
      )
  
  -- Movendo as chaves privadas para o diret�rio correto.
  os.execute(
      "cd " .. installPath .. "/specs/management;" ..
      "mkdir -p ../../data/certificates;" ..
      "mv *.key ../../data/certificates/;"
      )

  -- Criando chaves dos demos.
  
  -- Criando chaves para os testes.
  
  return true
end
