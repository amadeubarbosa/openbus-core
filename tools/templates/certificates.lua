

messages = {
}

configure_action = function(answers, tempdir, util)
  local installPath =  tempdir
  local openSSLGenerate = tempdir .. "/tools/shell/openssl-generate.ksh "
  -- Criando chaves dos serviços básicos.
  os.execute(
      "cd " .. installPath .. "/tools/management;" .. 
      openSSLGenerate .. "AccessControlService;" ..
      openSSLGenerate .. "RegistryService;" ..
      openSSLGenerate .. "SessionService;"
      )
  
  -- Movendo as chaves privadas para o diretório correto.
  os.execute(
      "cd " .. installPath .. "/tools/management;" ..
      "mkdir " .. installPath .. "/data/certificates;" ..
      "mv *.key " .. installPath .. "/data/certificates;"
      )

  -- Criando chaves dos demos.
  
  -- Criando chaves para os testes.
  
  return true
end
