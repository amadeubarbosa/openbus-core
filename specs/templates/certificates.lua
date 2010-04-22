

messages = {
}

configure_action = function(answers, path, util)
  local installPath =  path
  local openSSLGenerate = path .. "/specs/shell/openssl-generate.ksh "
  -- Criando chaves dos serviços básicos.
  os.execute(
      "cd " .. installPath .. "/specs/management;" .. 
      openSSLGenerate .. "AccessControlService;" ..
      openSSLGenerate .. "RegistryService;" ..
      openSSLGenerate .. "SessionService;" ..
      openSSLGenerate .. "ACSMonitor;" ..
      openSSLGenerate .. "RGSMonitor;"
      )
  
  -- Movendo as chaves privadas para o diretório correto.
  os.execute(
      "cd " .. installPath .. "/specs/management;" ..
      "mkdir " .. installPath .. "/data/certificates;" ..
      "mv *.key " .. installPath .. "/data/certificates;"
      )

  -- Criando chaves dos demos.
  
  -- Criando chaves para os testes.
  
  return true
end
