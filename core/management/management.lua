local lpw     = require "lpw"
local oil     = require "oil"
local Openbus = require "openbus.Openbus"
local Utils   = require "openbus.util.Utils"
local busLog  = require "openbus.util.Log"

local UI = require "core.management.ManagementUI"

-- Alias
local lower = string.lower

-- Verifica se as vari�vel de ambiente est� definida antes de continuar
local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if not IDLPATH_DIR then
  print("[ERRO] Caminho das IDLs n�o informado\n")
  os.exit(1)
end

-- Vari�veis que s�o referenciadas antes de sua cri��o
-- N�o usar globais para n�o export�-las para o comando 'script'
local login, password
local acshost, acsport
local acsmgm, getacsmgm
local rsmgm, getrsmgm

-- Guarda as fun��es que ser�o os tratadores das a��es de linha de comando
local handlers = {}

-- Nome do script principal (usado no help)
local program = arg[0]

-------------------------------------------------------------------------------
-- Constantes

-- Maximo de tentativas de conex�o com o barramento
local MAXRETRIES = 3

-- String de help
local help = [[

Uso: %s [op��es] --login=<usu�rio> <comando>

-------------------------------------------------------------------------------
- Op��es
  * Informa o endere�o do Servi�o de Acesso (padr�o 127.0.0.1):
    --acs-host=<endere�o>
  * Informa a porta do Servi�o de Acesso (padr�o 2089):
    --acs-port=<porta>
  * Aciona o verbose da API Openbus.
    --verbose=<level>

- Controle de Usu�rio
  * Adicionar usu�rio:
     --add-user=<id_usuario> --name=<nome>
  * Remover usu�rio:
     --del-user=<id_usuario>
  * Alterar nome:
     --set-user=<id_usuario> --name=<nome>
  * Mostrar todos os usu�rio:
     --list-user
  * Mostrar informa��es sobre um usu�rio:
     --list-user=<id_usuario>

- Controle de Sistema
  * Adicionar sistema:
     --add-system=<id_sistema> --description=<descri��o>
  * Remover sistema:
     --del-system=<id_sistema>
  * Alterar descri��o:
     --set-system=<id_sistema> --description=<descri��o>
  * Mostrar todos os sistemas:
     --list-system
  * Mostrar informa��es sobre um sistema:
     --list-system=<id_sistema>

- Controle de Implanta��o
  * Adicionar implanta��o:
     --add-deployment=<id_implanta��o> --system=<id_sistema> --description=<descri��o> --certificate=<arquivo>
  * Alterar descri��o:
     --set-deployment=<id_implanta��o> --description=<descri��o>
  * Alterar certificado:
     --set-deployment=<id_implanta��o> --certificate=<arquivo>
  * Remover implanta��o:
     --del-deployment=<id_implanta��o>
  * Mostrar todas implanta��es:
     --list-deployment
  * Mostrar informa��es sobre uma implanta��o:
     --list-deployment=<id_implanta��o>
  * Mostrar implanta��es de um sistema:
     --list-deployment --system=<id_sistema>

- Controle de Interface
  * Adicionar interface:
     --add-interface=<interface>
  * Remover interface:
     --del-interface=<interface>
  * Mostrar todas interfaces:
     --list-interface

- Controle de Autoriza��o
  * Conceder autoriza��o:
     --set-authorization=<id_membro> --grant=<interface> [--no-strict]
  * Revogar autoriza��o:
     --set-authorization=<id_membro> --revoke=<interface>
  * Remover autoriza��o:
     --del-authorization=<id_membro>
  * Mostrar todas as autoriza��es:
     --list-authorization
  * Mostrar autoriza��es do membro:
     --list-authorization=<id_membro>
  * Mostrar todas autoriza��es contendo as interfaces:
     --list-authorization --interface="<iface1> <iface2> ... <ifaceN>"

- Controle de Ofertas no Servi�o de Registro
  * Remover oferta:
     --del-offer=<id_oferta>
  * Mostrar todas interfaces ofertadas:
     --list-offer
  * Mostrar todas interfaces ofertadas por um membro:
     --list-offer=<id_membro>

- Script
  * Executa script Lua com um lote de comandos:
     --script=<arquivo>
  * Desfaz a execu��o de um script Lua com um lote de comandos:
    --undo-script=<arquivo>
-------------------------------------------------------------------------------
]]

-------------------------------------------------------------------------------
-- Define o parser da linha de comando.
--

-- Este valor � usado como uma constante para valor de comando ou par�metro.
local null = {}

--
-- Valor padr�o das op��es. Caso a linha de comando n�o informe, estes valores
-- ser�o copiados para a tabela de linha de comando.
--
local options = {
  ["acs-host"] = "127.0.0.1",
  ["acs-port"] = 2089,
  oilVerbose   = 0,
  verbose      = 0,
}

--
-- Lista de comandos que s�o aceitos pelo programa.
--
-- Cada comando pode aceitar diferentes par�metros. Esta ferramenta de parser
-- verifica se a linha de comando informada casa com os par�metros
-- m�nimos que o comando espera. Se forem passados mais par�metros que
-- o necess�rio, a ferramenta ignora.
--
-- O casamento � feito na seq��ncia que ele � descrito. A ferramenta retorna
-- ao encontrar a primeira forma v�lida.
--
-- Se a vari�vel 'n' for 1, isso indica que o pr�prio comando precisa
-- de um par�metro, ou seja, formato '--command=val'. Se 'n' for 0, ent�o o
-- comando � da forma '--command'.
--
-- O campo 'params' indica o nome dos par�metros esperados e se eles t�m valor
-- ou n�o, isto �, se eles seguem a forma do comando descrito acima:
--   --parameter=value
--   --parameter
--
-- Ap�s o parser, os par�metros e comandos que foram informados no
-- formato '--command' ter�o valor igual a 'null', inidicando que eles
-- est�o presentes, mas sem valor.
--
-- Par�metros n�o informados ter�o valor 'nil'. (comandos sempre devem
-- ser informados e nunca s�o nil)
--

local commands = {
  help = {
    --help
    {n = 0, params = {}}
  };
  ["add-system"] = {
    --add-system=<value> --description=<value>
    {n = 1, params = {description = 1}}
  };
  ["del-system"] = {
    {n = 1, params = {}}
  };
  ["set-system"] = {
    {n = 1, params = {description = 1}}
  };
  ["list-system"] = {
    {n = 0, params = {}},
    {n = 1, params = {}},
  };
  ["add-deployment"] = {
    {n = 1, params = {system = 1, description = 1, certificate=1}}
  };
  ["del-deployment"] = {
    {n = 1, params = {}}
  };
  ["set-deployment"] = {
    {n = 1, params = {description = 1, certificate = 1}},
    {n = 1, params = {description = 1}},
    {n = 1, params = {certificate = 1}},
   };
  ["list-deployment"] = {
    {n = 0, params = {system = 1}},
    {n = 0, params = {}},
    {n = 1, params = {}},
  };
  ["add-user"] = {
    {n = 1, params = {name = 1}}
  };
  ["del-user"] = {
    {n = 1, params = {}}
  };
  ["set-user"] = {
    {n = 1, params = {name = 1}}
  };
  ["list-user"] = {
    {n = 0, params = {}},
    {n = 1, params = {}},
  };
  ["add-interface"] = {
    {n = 1, params = {}}
  };
  ["del-interface"] = {
    {n = 1, params = {}}
  };
  ["list-interface"] = {
    {n = 0, params = {}}
  };
  ["set-authorization"] = {
    {n = 1, params={grant = 1, ["no-strict"] = 0}},
    {n = 1, params={grant = 1}},
    {n = 1, params={revoke = 1}},
  };
  ["del-authorization"] = {
    {n = 1, params = {}}
  };
  ["list-authorization"] = {
    {n = 0, params = {}},
    {n = 1, params = {interface = 1}},
    {n = 1, params = {}},
  };
  ["list-offer"] = {
    {n = 0, params = {broken = 0}},
    {n = 1, params = {broken = 0}},
    {n = 0, params = {}},
    {n = 1, params = {}},
  };
  ["del-offer"] = {
    {n = 1, params = {}},
  };
  ["script"] = {
    {n = 1, params = {}},
  };
  ["undo-script"] = {
    {n = 1, params = {}},
  };
}

---
-- Realiza o parser da linha de comando.
--
-- Se um par�metro n�o possui valor informado, utilizamos um marcador �nico
-- 'null' em vez de nil, para indicar aus�ncia. Isso diferencia o fato
-- do par�metro n�o ter valor de ele n�o ter sido informado (neste caso, nil).
--
-- @param argv Uma tabela com os par�metros da linha de comando.
--
-- @return Uma tabela onde a chave � o nome do par�metro. Em caso de erro,
-- � retornado nil, seguido de uma mensagem.
--
local function parseline(argv)
  local line = {}
  for _, param in ipairs(argv) do
    local name, val = string.match(param, "^%-%-([^=]+)=(.+)$")
    if name then
      line[name] = val
    else
      name = string.match(param, "^%-%-([^=]+)$")
      if name then
        line[name] = null
      else
        return nil, string.format("Par�metro inv�lido: %s", param)
      end
    end
  end
  return line
end

---
-- Verifica se as op��es foram informadas e completa os valores ausentes.
--
-- @para params Os par�metros extra�dos da linha de comando.
--
-- @return true se as op��es foram inseridas com sucesso. No caso de
-- erro, retorna false e uma mensagem.
--
local function addoptions(params)
  for opt, val in pairs(options) do
    if not params[opt] then
      params[opt] = val
    elseif params[opt] == null then
      return false, string.format("Op��o inv�lida: %s", opt)
    end
  end
  return true
end

---
-- Verifica na a tabela de par�metros possui um, e apenas um, comando.
--
-- @param params Par�metros extra�dos da linha de comando.
--
-- @return Em caso de sucesso, retorna o nome do comando, seu valor de
-- linha de comando e sua descri��o na tabela geral de comandos. No caso
-- de erro, retorna nil seguido de uma mensagem.
--
local function findcommand(params)
  local cmd
  for name in pairs(commands) do
    if params[name] then
      if cmd then
        return nil, "Conflito: mais de um comando informado"
      else
        cmd = name
      end
    end
  end
  if cmd then
    return cmd, params[cmd], commands[cmd]
  end
  return nil, "Comando inv�lido"
end

---
-- Realiza o parser da linha de comando.
--
-- @param argv Array com a linha de comando.
--
-- @return Tabela com os campos 'command' contendo o nome do comando
-- e 'params' os par�metros vindos da linha de comando.
--
local function parse(argv)
  local params, msg, succ, cmdname
  params, msg = parseline(argv)
  if not params then
    return nil, msg
  end
  succ, msg = addoptions(params)
  if not succ then
    return nil, msg
  end
  cmdname, cmdval, cmddesc = findcommand(params)
  if not cmdname then
    return nil, cmdval
  end
  -- Verifica se os par�metros necess�rios existem e identifica
  -- qual o string.formato do comando se refere.
  local found
  for _, desc in ipairs(cmddesc) do
    -- O comando possui valor?
    if (desc.n == 1 and cmdval ~= null) or
       (desc.n == 0 and cmdval == null)
    then
      -- Os par�metros existem e possuem valor?
      found = desc
      for k, v in pairs(desc.params) do
        if not params[k] or (v == 1 and params[k] == null) or
           (v == 0 and params[k] ~= null)
        then
          found = nil
          break
        end
      end
      if found then break end
    end
  end
  if not found then
    return nil, "Par�metros inv�lidos"
  end
  return {
    name = cmdname,
    params = params,
  }
end

-------------------------------------------------------------------------------
-- Fun��es auxiliares

---
-- Fun��o auxiliar para imprimir string formatada.
--
-- @param str String a ser formatada e impressa.
-- @param ... Argumentos para formatar a string.
--
local function printf(str, ...)
  print(string.format(str, ...))
end

---
-- Testa se o identificar de sistema e implanta��o possuem um formato v�lido.
--
-- @param id Identificador
-- @return true se ele possui um formato v�lido, false caso contr�rio
--
local function validId(id)
  return (string.match(id, "^[_a-zA-Z0-9]+$") ~= nil)
end

-------------------------------------------------------------------------------
-- Fun��es auxiliares para os comandos de script

-- Tabela de a��es contidas no arquivo de script
local scripts = {}

---
-- Reseta a tabela de a��es lidas do arquivo de script
--
local function resetScripts()
  scripts = {}
  scripts.User = {}
  scripts.System = {}
  scripts.SystemDeployment = {}
  scripts.Interface = {}
  scripts.Grant = {}
  scripts.Revoke = {}
end

---
-- L� o arquivo de script e preenche a tabela 'scripts' com os comandos lidos.
--
-- @return Retorna true se leu o arquivo se erros e false caso contr�rio.
--
local function readScriptFile(cmd)
  resetScripts()
  local f, err, str, func, succ
  f, err = io.open(cmd.params[cmd.name])
  if not f then
    printf("[ERRO] Falha ao abrir arquivo: %s", err)
    return false
  end
  str, err = f:read("*a")
  f:close()
  if not str then
    printf("[ERRO] Falha ao ler conte�do do arquivo: %s", err)
    return false
  end
  func, err = loadstring(str)
  if not func then
    printf("[ERRO] Falha ao carregar script: %s", err)
    return false
  end
  succ, err = oil.pcall(func)
  if not succ then
    printf("[ERRO] Falha ao executar o script: %s", tostring(err))
    return false
  end
  return true
end

---
-- Cadastra um usu�rio
--
-- @param user Tabela com os campos 'id' e 'name'
--
local function doUser(user)
  local cmd = {}
  cmd.name = "add-user"
  cmd.params = {}
  cmd.params[cmd.name] = user.id
  cmd.params.name = user.name
  handlers[cmd.name](cmd)
end

---
-- Descadastra um usu�rio
--
-- @param user Tabela com o campo 'id'
--
local function undoUser(user)
  local cmd = {}
  cmd.name = "del-user"
  cmd.params = {}
  cmd.params[cmd.name] = user.id
  handlers[cmd.name](cmd)
end

---
-- Cadastra um sistema
--
-- @param system Tabela com os campos 'id' e 'description'
--
local function doSystem(system)
  local cmd = {}
  cmd.name = "add-system"
  cmd.params = {}
  cmd.params[cmd.name] = system.id
  cmd.params.description = system.description
  handlers[cmd.name](cmd)
end

---
-- Descadastra um sistema
--
-- @param system Tabela com os campos 'id'
--
local function undoSystem(system)
  local cmd = {}
  cmd.name = "del-system"
  cmd.params = {}
  cmd.params[cmd.name] = system.id
  handlers[cmd.name](cmd)
end

---
-- Cadastra uma implanta��o.
--
-- @param depl Tabela com os campos 'id', 'systemId' e 'description'
--
local function doSystemDeployment(depl)
  local cmd = {}
  cmd.name = "add-deployment"
  cmd.params = {}
  cmd.params[cmd.name] = depl.id
  cmd.params.system = depl.system
  cmd.params.description = depl.description
  cmd.params.certificate = depl.certificate
  handlers[cmd.name](cmd)
end

---
-- Descadastra uma implanta��o.
--
-- @param depl Tabela com o campo 'id'
--
local function undoSystemDeployment(depl)
  local cmd = {}
  cmd.name = "del-deployment"
  cmd.params = {}
  cmd.params[cmd.name] = depl.id
  handlers[cmd.name](cmd)
end

---
-- Cadastra uma interface.
--
-- @param iface Tabela com um campo 'id' contendo o repID da interface.
--
local function doInterface(iface)
  local cmd = {}
  cmd.name = "add-interface"
  cmd.params = {}
  cmd.params[cmd.name] = iface.id
  handlers[cmd.name](cmd)
end

---
-- Descadastra uma interface.
--
-- @param iface Tabela com um campo 'id' contendo o repID da interface.
--
local function undoInterface(iface)
  local cmd = {}
  cmd.name = "del-interface"
  cmd.params = {}
  cmd.params[cmd.name] = iface.id
  handlers[cmd.name](cmd)
end

---
-- Concede a autoriza��o para um conjunto de interfaces.
--
-- @param auth Tabela com o os campos 'id', identificador do membro,
-- e 'interfaces', array de repID de interfaces para autorizar.
--
local function doGrant(auth)
  local cmd = {}
  cmd.name = "set-authorization"
  cmd.params = {}
  cmd.params[cmd.name] = auth.id
  if auth.strict == false then
    cmd.params["no-strict"] = null
  end
  for n, iface in ipairs(auth.interfaces) do
    cmd.params.grant = iface
    handlers[cmd.name](cmd)
  end
end

---
-- Revoga autoriza��o de um conjunto de interfaces.
--
-- @param auth Tabela com os campos 'id', identificador do membro,
-- e 'interfaces', array de repID de interfaces para revogar.
--
local function doRevoke(auth)
  local cmd = {}
  cmd.name = "set-authorization"
  cmd.params = {}
  cmd.params[cmd.name] = auth.id
  for n, iface in ipairs(auth.interfaces) do
    cmd.params.revoke = iface
    handlers[cmd.name](cmd)
  end
end

-------------------------------------------------------------------------------
-- Aliases
--
local ACS_UserNonExistentException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/access_control_service/UserNonExistent:1.0"
local ACS_UserAlreadyExistsException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/access_control_service/UserAlreadyExists:1.0"
--
local ACS_SystemInUseException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/access_control_service/SystemInUse:1.0"
local ACS_SystemNonExistentException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/access_control_service/SystemNonExistent:1.0"
local ACS_SystemAlreadyExistsException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/access_control_service/SystemAlreadyExists:1.0"
--
local ACS_InvalidCertificateException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/access_control_service/InvalidCertificate:1.0"
local ACS_SystemDeploymentNonExistentException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/access_control_service/SystemDeploymentNonExistent:1.0"
local ACS_SystemDeploymentAlreadyExistsException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/access_control_service/SystemDeploymentAlreadyExists:1.0"
--
local RS_InterfaceIdentifierInUseException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/registry_service/InterfaceIdentifierInUse:1.0"
local RS_InterfaceIdentifierNonExistentException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/registry_service/InterfaceIdentifierNonExistent:1.0"
local RS_InterfaceIdentifierAlreadyExistsException =
    "IDL:tecgraf/openbus/core/"..Utils.IDL_VERSION..
    "/registry_service/InterfaceIdentifierAlreadyExists:1.0"
--
local RS_MemberNonExistentException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/registry_service/MemberNonExistent:1.0"
local RS_InvalidRegularExpressionException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/registry_service/InvalidRegularExpression:1.0"
local RS_AuthorizationNonExistentException = "IDL:tecgraf/openbus/core/"..
    Utils.IDL_VERSION.."/registry_service/AuthorizationNonExistent:1.0"

-------------------------------------------------------------------------------
-- Define os tratadores de comandos passados como argumento para a ferramenta.
--

---
-- Exibe o menu de ajuda da ferramenta.
--
-- @param cmd Comando e seus argumentos.
--
handlers["help"] = function(cmd)
  printf(help, program)
end

---
-- Adiciona um novo sistema no barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-system"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  if validId(id) then
    local succ, err = acsmgm:addSystem(id, cmd.params.description)
    if succ then
      printf("[INFO] Sistema '%s' cadastrado com sucesso", id)
    elseif err[1] == ACS_SystemAlreadyExistsException then
      printf("[ERRO] Sistema '%s' j� cadastrado", id)
    else
      printf("[ERRO] Falha ao adicionar sistema '%s': %s", id, err[1])
    end
  else
    printf("[ERRO] Falha ao adicionar sistema '%s': " ..
           "identificador inv�lido", id)
  end
end

---
-- Remove um sistema do barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-system"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  local succ, err = acsmgm:removeSystem(id)
  if succ then
    printf("[INFO] Sistema '%s' removido com sucesso", id)
  elseif err[1] == ACS_SystemInUseException then
    printf("[ERRO] Sistema '%s' em uso", id)
  elseif err[1] == ACS_SystemNonExistentException then
    printf("[ERRO] Sistema '%s' n�o cadastrado", id)
  else
    printf("[ERRO] Falha ao remover sistema '%s': %s", id, err[1])
  end
end

---
-- Exibe informa��es sobre os sistemas.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-system"] = function(cmd)
  local succ
  local systems
  local acsmgm = getacsmgm()
  -- Busca todos
  if cmd.params[cmd.name] == null then
    succ, systems = acsmgm:getSystems()
    if not succ then
      printf("[ERRO] Falha ao recuperar informa��es: %s", systems[1])
      return
    end
  else
    -- Busca um sistema espec�fico
    local succ, system = acsmgm:getSystem(cmd.params[cmd.name])
    if succ then
      systems = {system}
    else
      if system[1] == ACS_SystemNonExistentException then
        systems = {}
      else
        printf("[ERRO] Falha ao recuperar informa��es: %s", system[1])
        return
      end
    end
  end

  UI.showSystem(systems)
end

---
-- Altera informa��es do sistema.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-system"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  local succ, err = acsmgm:setSystemDescription(id,cmd.params.description)
  if succ then
    print(string.format("[INFO] Sistema '%s' atualizado com sucesso", id))
  elseif err[1] == ACS_SystemNonExistentException then
    print(string.format("[ERRO] Sistema '%s' n�o cadastrado", id))
  else
    print(string.format("[ERRO] Falha ao atualizar sistema '%s': %s", id,
      err[1]))
  end
end

---
-- Adiciona uma nova implanta��o.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-deployment"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  if validId(id) then
    local f = io.open(cmd.params.certificate)
    if not f then
      print("[ERRO] N�o foi poss�vel localizar arquivo de certificado")
      return
    end
    local cert = f:read("*a")
    if not cert then
      print("[ERRO] N�o foi poss�vel ler o certificado")
      return
    end
    f:close()
    local succ, err = acsmgm:addSystemDeployment(id, cmd.params.system,
      cmd.params.description, cert)
    if succ then
      printf("[INFO] Implanta��o '%s' cadastrada com sucesso", id)
    elseif err[1] == ACS_SystemDeploymentAlreadyExistsException then
      printf("[ERRO] Implanta��o '%s' j� cadastrada", id)
    elseif err[1] == ACS_SystemNonExistentException then
      printf("[ERRO] Sistema '%s' n�o cadastrado", cmd.params.system)
    elseif err[1] == ACS_InvalidCertificateException then
      printf("[ERRO] Falha ao adicionar implanta��o '%s': certificado inv�lido",
        id)
    else
      printf("[ERRO] Falha ao adicionar implanta��o '%s': %s", id, err[1])
    end
  else
    printf("[ERRO] Falha ao adicionar implanta��o '%s': " ..
           "identificador inv�lido", id)
  end
end

---
-- Remove uma implanta��o.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-deployment"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  local succ, err = acsmgm:removeSystemDeployment(id)
  if succ then
    printf("[INFO] Implanta��o '%s' removida com sucesso", id)
  elseif err[1] == ACS_SystemDeploymentNonExistentException then
    printf("[ERRO] Implanta��o '%s' n�o cadastrada", id)
  else
    printf("[ERRO] Falha ao remover implanta��o '%s': %s", id, err[1])
  end
end

---
-- Altera informa��es da implanta��o.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-deployment"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  if cmd.params.certificate then
    local f = io.open(cmd.params.certificate)
    if not f then
      print("[ERRO] N�o foi poss�vel localizar arquivo de certificado")
      return
    end
    local cert = f:read("*a")
    if not cert then
      print("[ERRO] N�o foi poss�vel ler o certificado")
      return
    end
    f:close()
    local succ, err = acsmgm:setSystemDeploymentCertificate(id, cert)
    if succ then
      printf("[INFO] Certificado da implanta��o '%s' atualizado com sucesso",
        id)
    elseif err[1] == ACS_SystemDeploymentNonExistentException then
      printf("[ERRO] Implanta��o '%s' n�o cadastrada", id)
    elseif err[1] == ACS_InvalidCertificateException then
      printf("[ERRO] Falha ao adicionar implanta��o '%s': certificado inv�lido",
        id)
    else
      printf("[ERRO] Falha ao atualizar certificado da implanta��o '%s': %s",
        id, err[1])
    end
  end
  if cmd.params.description then
    local succ, err = acsmgm:setSystemDeploymentDescription(id,
      cmd.params.description)
    if succ then
      printf("[INFO] Descri��o da imlanta��o '%s' atualizada com sucesso", id)
    elseif err[1] == ACS_SystemDeploymentNonExistentException then
      printf("[ERRO] Implanta��o '%s' n�o cadastrada", id)
    else
      printf("[ERRO] Falha ao atualizar descri��o da implanta��o '%s': %s",
        id, err[1])
    end
  end
end

---
-- Exibe informa��es das implanta��es.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-deployment"] = function(cmd)
  local succ
  local depls
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  local system = cmd.params.system
  -- Busca apenas uma implanta��o
  if id and id ~= null then
    local succ, depl = acsmgm:getSystemDeployment(id)
    if succ then
      depls = { depl }
    elseif depl[1] == ACS_SystemDeploymentNonExistentException then
      depls = {}
    else
      printf("[ERRO] Falha ao recuperar informa��es: %s", depl[1])
      return
    end
  elseif system then
    -- Filtra por sistema
    succ, depls = acsmgm:getSystemDeploymentsBySystemId(system)
    if not succ then
       printf("[ERRO] Falha ao recuperar informa��es %s: %s", system, depls[1])
      return
    end
  else
    -- Busca todos
    succ, depls = acsmgm:getSystemDeployments()
    if not succ then
       printf("[ERRO] Falha ao recuperar informa��es: %s", depls[1])
      return
    end
  end

  UI.showSystemDeployment(depls)
end

---
-- Adiciona um novo usu�rio no barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-user"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  if validId(id) then
    local succ, err = acsmgm:addUser(id, cmd.params.name)
    if succ then
      printf("[INFO] Usu�rio '%s' cadastrado com sucesso", id)
    elseif err[1] == ACS_UserAlreadyExistsException then
      printf("[ERRO] Usu�rio '%s' j� cadastrado", id)
    else
      printf("[ERRO] Falha ao adicionar usu�rio '%s': %s", id, err[1])
    end
  else
    printf("[ERRO] Falha ao adicionar usu�rio '%s': " ..
           "identificador inv�lido", id)
  end
end

---
-- Remove um usu�rio do barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-user"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  local succ, err = acsmgm:removeUser(id)
  if succ then
    printf("[INFO] Usu�rio '%s' removido com sucesso", id)
  elseif err[1] == ACS_UserNonExistentException then
    printf("[ERRO] Usu�rio '%s' n�o cadastrado", id)
  else
    printf("[ERRO] Falha ao remover usu�rio '%s': %s", id, err[1])
  end
end

---
-- Altera informa��es do usu�rio.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-user"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  local succ, err = acsmgm:setUserName(id, cmd.params.name)
  if succ then
    print(string.format("[INFO] Usu�rio '%s' atualizado com sucesso", id))
  elseif err[1] == ACS_UserNonExistentException then
    print(string.format("[ERRO] Usu�rio '%s' n�o cadastrado", id))
  else
    print(string.format("[ERRO] Falha ao atualizar usu�rio '%s': %s", id,
      err[1]))
  end
end

---
-- Exibe informa��es sobre os usu�rios.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-user"] = function(cmd)
  local succ
  local users
  local acsmgm = getacsmgm()
  -- Busca todos
  if cmd.params[cmd.name] == null then
    succ, users = acsmgm:getUsers()
    if not succ then
      printf("[ERRO] Falha ao recuperar informa��es: %s", users[1])
      return
    end
  else
    -- Busca um espec�fico
    local succ, user = acsmgm:getUser(cmd.params[cmd.name])
    if succ then
      users = {user}
    else
      if user[1] == ACS_UserNonExistentException then
        users = {}
      else
        printf("[ERRO] Falha ao recuperar informa��es: %s", user[1])
        return
      end
    end
  end

  UI.showUser(users)
end

---
-- Adiciona um nova interface.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-interface"] = function(cmd)
  local rsmgm = getrsmgm()
  local iface = cmd.params[cmd.name]
  local succ, err = rsmgm:addInterfaceIdentifier(iface)
  if succ then
    printf("[INFO] Interface '%s' cadastrada com sucesso", iface)
  elseif err[1] == RS_InterfaceIdentifierAlreadyExistsException then
    printf("[ERRO] Interface '%s' j� cadastrada", iface)
  else
    printf("[ERRO] Falha ao cadastrar interface '%s': %s", iface, err[1])
  end
end

---
-- Remove uma interface.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-interface"] = function(cmd)
  local rsmgm = getrsmgm()
  local iface = cmd.params[cmd.name]
  local succ, err = rsmgm:removeInterfaceIdentifier(iface)
  if succ then
    printf("[INFO] Interface '%s' removida com sucesso", iface)
  elseif err[1] == RS_InterfaceIdentifierInUseException then
    printf("[ERRO] Interface '%s' em uso", iface)
  elseif err[1] == RS_InterfaceIdentifierNonExistentException then
    printf("[ERRO] Interface '%s' n�o cadastrada", iface)
  else
    printf("[ERRO] Falha ao remover interface: %s", err[1])
  end
end

---
-- Exibe as interfaces cadastradas.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-interface"] = function(cmd)
  local rsmgm = getrsmgm()
  local succ, ifaces = rsmgm:getInterfaceIdentifiers()
  if not succ then
    printf("[ERRO] Falha ao exibir interfaces: %s",ifaces[1])
    return
  end

  UI.showInterface(ifaces)
end

---
-- Altera a autoriza��o de um membro do barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-authorization"] = function(cmd)
  local succ, err, msg, iface
  local rsmgm = getrsmgm()
  local id = cmd.params[cmd.name]
  -- Concede uma autoriza��o
  if cmd.params.grant then
    iface = cmd.params.grant
    succ, err = rsmgm:grant(id, iface, not cmd.params["no-strict"])
    msg = string.format("[INFO] Autoriza��o concedida a '%s': %s", id, iface)
  else
    -- Revoga autoriza��o
    iface = cmd.params.revoke
    succ, err = rsmgm:revoke(id, iface)
    msg = string.format("[INFO] Autoriza��o revogada de '%s': %s", id, iface)
  end
  if succ then
    print(msg)
  elseif err[1] == RS_MemberNonExistentException then
    printf("[ERRO] Membro '%s' n�o cadastrado", id)
  elseif err[1] == RS_InterfaceIdentifierNonExistentException then
    printf("[ERRO] Interface '%s' n�o cadastrada", iface)
  elseif err[1] == RS_AuthorizationNonExistentException then
    printf("[ERRO] Implanta��o '%s' n�o possui autoriza��o para '%s'",
      id, iface)
  elseif err[1] == RS_InvalidRegularExpressionException then
    printf("[ERRO] Express�o regular inv�lida: %s", iface)
  else
    printf("[ERRO] Falha ao alterar autoriza��o: %s", err[1])
  end
end

---
-- Remove todas as autoriza��es de uma implanta��o
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-authorization"] = function(cmd)
  local rsmgm = getrsmgm()
  local id = cmd.params[cmd.name]
  local succ, err = rsmgm:removeAuthorization(id)
  if succ then
    printf("[INFO] Autoriza��es de '%s' removidas com sucesso",
      cmd.params[cmd.name])
  elseif err[1] == RS_AuthorizationNonExistentException then
    printf("[ERRO] Implanta��o '%s' n�o possui autoriza��es", id)
  else
    printf("[ERRO] Falha ao remover autoriza��es: %s", err[1])
  end
end

---
-- Exibe as autoriza��es.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-authorization"] = function(cmd)
  local succ
  local auths
  local rsmgm = getrsmgm()
  local id = cmd.params[cmd.name]
  if id and id ~= null then
    -- Busca de uma �nica implanta��o
    local succ, auth = rsmgm:getAuthorization(id)
    if succ then
      auths = { auth }
    elseif auth[1] == RS_AuthorizationNonExistentException then
      printf("[ERRO] Membro '%s' n�o possui autoriza��o", id)
      return
    else
      printf("[ERRO] Falha ao recuperar informa��es: %s", auth[1])
      return
    end
  elseif cmd.params.interface then
    -- Filtra por interface
    local ifaces = {}
    for iface in string.gmatch(cmd.params.interface, "%S+") do
      ifaces[#ifaces+1] = iface
    end
    succ, auths = rsmgm:getAuthorizationsByInterfaceId(ifaces)
    if not succ then
      printf("[ERRO] Falha ao recuperar informa��es: %s", auths[1])
      return
    end
  else
    -- Busca todas
    succ, auths = rsmgm:getAuthorizations()
    if not succ then
      printf("[ERRO] Falha ao recuperar informa��es: %s", auths[1])
      return
    end
  end

  UI.showAuthorization(auths)
end

--
-- Lista as interfaces oferecidas no registro.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-offer"] = function(cmd)
  local succ
  local offers
  local rsmgm = getrsmgm()
  if cmd.params[cmd.name] == null then
    succ, offers = rsmgm:getOfferedInterfaces()
    if not succ then
      printf("[ERRO] Falha ao listar interfaces oferecidas: %s",offers[1])
      return
    end
  else
    succ, offers = rsmgm:getOfferedInterfacesByMember(cmd.params[cmd.name])
    if not succ then
      printf("[ERRO] Falha ao listar interfaces oferecidas %s: %s",
         cmd.params[cmd.name], offers[1])
      return
    end
  end

  UI.showOffer(offers)
end

--
-- Lista as interfaces oferecidas no registro.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-offer"] = function(cmd)
  local rsmgm = getrsmgm()
  local id = cmd.params[cmd.name]
  local succ, removed = rsmgm:unregister(id)
  if succ and removed then
    print("[INFO] Oferta removida com sucesso")
  else
    printf("[ERRO] Falha ao remover oferta '%s'", id)
  end
end

---
-- Carrega e executa um script Lua para lote de comandos
--
-- @param cmd Comando e seus argumentos.
--
handlers["script"] = function(cmd)
  local succ = readScriptFile(cmd)
  if not succ then
    return
  end
  for _,v in ipairs(scripts.User) do
    doUser(v)
  end
  for _,v in ipairs(scripts.System) do
    doSystem(v)
  end
  for _,v in ipairs(scripts.SystemDeployment) do
    doSystemDeployment(v)
  end
  for _,v in ipairs(scripts.Interface) do
    doInterface(v)
  end
  for _,v in ipairs(scripts.Grant) do
    doGrant(v)
  end
  for _,v in ipairs(scripts.Revoke) do
    doRevoke(v)
  end
end

---
-- Carrega e desfaz um script Lua para lote de comandos
--
-- @param cmd Comando e seus argumentos.
--
handlers["undo-script"] = function(cmd)
  local succ = readScriptFile(cmd)
  if not succ then
    return
  end
  for _,v in ipairs(scripts.Revoke) do
    doGrant(v)
  end
  for _,v in ipairs(scripts.Grant) do
    doRevoke(v)
  end
  for _,v in ipairs(scripts.Interface) do
    undoInterface(v)
  end
  for _,v in ipairs(scripts.SystemDeployment) do
    undoSystemDeployment(v)
  end
  for _,v in ipairs(scripts.System) do
    undoSystem(v)
  end
  for _,v in ipairs(scripts.User) do
    undoUser(v)
  end
end

-------------------------------------------------------------------------------
-- Fun��es exportadas para o script Lua carregado pelo comando 'script'

---
-- Aborta a execu��o do script reportando um erro nos argumentos.
--
local function argerror()
  printf("[ERRO] Par�metro inv�lido (linha %d)",
    debug.getinfo(3, 'l').currentline)
  error()
end

---
-- Valida o comando de script 'User' e insera na tabela 'scripts'
--
-- @param user Tabela com os campos 'id' e 'name'
--
function User(user)
  if not (type(user) == "table" and type(user.id) == "string" and
     type(user.name) == "string")
  then
    argerror()
  end
  table.insert(scripts.User, user)
end

---
-- Valida o comando de script 'System' e insera na tabela 'scripts'
--
-- @param system Tabela com os campos 'id' e 'description'
--
function System(system)
  if not (type(system) == "table" and type(system.id) == "string" and
     type(system.description) == "string")
  then
    argerror()
  end
  table.insert(scripts.System, system)
end

---
-- Valida o comando de script 'SystemDeployment' e insera na tabela 'scripts'
--
-- @param depl Tabela com os campos 'id', 'systemId' e 'description'
--
function SystemDeployment(depl)
  if not (type(depl) == "table" and type(depl.id) == "string" and
     type(depl.description) == "string" and type(depl.system) == "string" and
     type(depl.certificate) == "string")
  then
    argerror()
  end
  table.insert(scripts.SystemDeployment, depl)
end

---
-- Valida o comando de script 'Interface' e insera na tabela 'scripts'
--
-- @param iface Tabela com um campo 'id' contendo o repID da interface.
--
function Interface(iface)
  if not (type(iface) == "table" and type(iface.id) == "string") then
    argerror()
  end
  table.insert(scripts.Interface, iface)
end

---
-- Valida o comando de script 'Grant' e insera na tabela 'scripts'
--
-- @param auth Tabela com o os campos 'id', identificador do membro,
-- e 'interfaces', array de repID de interfaces para autorizar.
--
function Grant(auth)
  if not (type(auth) == "table" and type(auth.id) == "string" and
    type(auth.interfaces) == "table" and (type(auth.strict) == "nil" or
    type(auth.strict) == "boolean"))
  then
    argerror()
  end
  table.insert(scripts.Grant, auth)
end

---
-- Valida o comando de script 'Revoke' e insera na tabela 'scripts'
--
-- @param auth Tabela com os campos 'id', identificador do membro,
-- e 'interfaces', array de repID de interfaces para revogar.
--
function Revoke(auth)
  if not (type(auth) == "table" and type(auth.id) == "string" and
     type(auth.interfaces) == "table")
  then
    argerror()
  end
  table.insert(scripts.Revoke, auth)
end

-------------------------------------------------------------------------------
-- Se��o de conex�o com o barramento e os servi�os b�sicos

---
-- Efetua a conex�o com o barramento.
--
-- @param retry Par�metro opcional que indica o n�mero da tentativa de
-- reconex�o.
---
local function connect(retry)
  retry = retry or 0
  if not Openbus:isConnected() then
    local localPassword = password
    if not localPassword then
      localPassword = lpw.getpass("Senha: ")
    end
    if retry == 0 then
      local initialized = Openbus:init(acshost, acsport)
      if not initialized then
        print(string.format(
            "[ERRO] Openbus n�o pode ser inicializado. Verifique se existe um barramento em %s:%s",
            acshost or "nil", acsport or "nil"))
        return
      end
      local orb = Openbus:getORB()
      orb:loadidlfile(IDLPATH_DIR .. "/"..Utils.IDL_VERSION..
          "/registry_service.idl")
      orb:loadidlfile(IDLPATH_DIR .. "/"..Utils.IDL_VERSION..
          "/access_control_service.idl")
    end
    if Openbus:connectByLoginPassword(login, localPassword) == false then
      print("[ERRO] Falha no login.")
      retry = retry + 1
      if (not password) and (retry < MAXRETRIES) then
        print("Tente novamente.")
        connect(retry)
      end
    end
  end
end

---
-- Recupera refer�ncia � faceta de gerenciamento do Servi�o de Acesso.
--
-- @return Faceta de gerenciamento do ACS.
--
function getacsmgm()
  if acsmgm then
    return acsmgm
  end
  connect()
  local orb = Openbus:getORB()
  local acs = Openbus:getAccessControlService()
  if not acs then
    print("[ERRO] Servi�o de Controle de Acesso n�o est� conectado.")
    os.exit(1)
  end
  local ic = acs:_component()
  ic = orb:narrow(ic, "IDL:scs/core/IComponent:1.0")
  acsmgm = ic:getFacetByName("IManagement_" .. Utils.IDL_VERSION)
  acsmgm = orb:narrow(acsmgm, Utils.MANAGEMENT_ACS_INTERFACE)
  acsmgm = orb:newproxy(acsmgm, "protected")
  return acsmgm
end

---
-- Recupera refer�ncia � faceta de gerenciamento do Servi�o de Registro.
--
-- @return Faceta de gerenciamento do RS.
--
function getrsmgm()
  if rsmgm then
    return rsmgm
  end
  connect()
  local orb = Openbus:getORB()
  local rs = Openbus:getRegistryService()
  if not rs then
    print("[ERRO] Servi�o de Registro n�o est� conectado.")
    os.exit(1)
  end
  ic = rs:_component()
  ic = orb:narrow(ic, "IDL:scs/core/IComponent:1.0")
  rsmgm = ic:getFacetByName("IManagement_" .. Utils.IDL_VERSION)
  rsmgm = orb:narrow(rsmgm, Utils.MANAGEMENT_RS_INTERFACE)
  rsmgm = orb:newproxy(rsmgm, "protected")
  return rsmgm
end

-------------------------------------------------------------------------------
-- Fun��o Principal
--

-- Faz o parser da linha de comando.
-- Verifica se houve erro e j� despacha o comando de ajuda para evitar
-- a conex�o com os servi�os do barramento
local command, msg = parse{...}
if not command then
  print("[ERRO] " .. msg)
  print("[HINT] --help")
  os.exit(1)
elseif command.name == "help" then
  handlers.help(command)
  os.exit(1)
elseif not command.params.login then
  print("[ERRO] Usu�rio n�o informado")
  os.exit(1)
end

-- Recupera os valores globais
login    = command.params.login
password = command.params.password
acshost  = command.params["acs-host"]
acsport  = tonumber(command.params["acs-port"])

oil.verbose:level(tonumber(command.params.oilVerbose))
busLog:level(tonumber(command.params.verbose))

---
-- Fun��o principal respons�vel por despachar o comando.
--
local function main()
  local f = handlers[command.name]
  if f then
    f(command)
  end
  --
  if Openbus:isConnected() then
    Openbus:disconnect()
  end
  os.exit()
end

oil.main(function()
  print(oil.pcall(main))
end)
