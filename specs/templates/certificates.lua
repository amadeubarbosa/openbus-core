

messages = {
  { name = "test",
    msg = "Você deseja criar os certificados do teste ?",
    type = "string",
    value = "nao",
  },
}

configure_action = function(answers, path, util)
  local installPath =  path
  local openSSLGenerate = "../shell/openssl-generate.ksh -n "
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
      "mkdir -p ../../data/certificates;" ..
      "mv *.key ../../data/certificates/;"
      )

  -- Criando chaves dos demos.

  -- Criando chaves para os testes.
  if string.upper(answers.test):find("SIM") then
    openSSLGenerate = "../../../specs/specs/shell/openssl-generate.ksh -n "

    os.execute(
        "cd " .. installPath .. "/core/test/management;" ..
        openSSLGenerate .. "TesteBarramento;"
        )
  end


  return true
end
