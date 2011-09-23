local lpw     = require "lpw"
local oil     = require "oil"
local openbus = require "openbus"
local log     = require "openbus.util.logger"

local printer = require "openbus.core.admin.print"

-- Alias
local lower = string.lower
local next  = next

-- Variáveis que são referenciadas antes de sua crição
-- Não usar globais para não exportá-las para o comando 'script'
local login, password
local host, port
local connection

-- Guarda as funções que serão os tratadores das ações de linha de comando
local handlers = {}

-- Nome do script principal (usado no help)
local program = arg[0]

-------------------------------------------------------------------------------
-- Constantes

-- Maximo de tentativas de conexão com o barramento
local MAXRETRIES = 3

-- String de help
local help = [[

Uso: %s [opções] --login=<usuário> <comando>

-------------------------------------------------------------------------------
- Opções
  * Informa o endereço do Barramento (padrão 127.0.0.1):
    --host=<endereço>
  * Informa a porta do Barramento (padrão 2089):
    --port=<porta>
  * Aciona o verbose da API Openbus.
    --verbose=<level>

- Controle de Categoria
  * Adicionar categoria:
     --add-category=<id_categoria> --name=<nome>
  * Remover sistema:
     --del-category=<id_categoria>
  * Alterar o nome descritivo da categoria:
     --set-category=<id_categoria> --name=<nome>
  * Mostrar todas as categorias:
     --list-category
  * Mostrar informações sobre uma categoria:
     --list-category=<id_categoria>

- Controle de Entidade
  * Adicionar entidade:
     --add-entity=<id_entidade> --category<id_categoria> --name=<nome> 
  * Alterar descrição:
     --set-entity=<id_entidade> --name=<nome>
  * Remover entidade:
     --del-entity=<id_entidade>
  * Mostrar todas as entidades:
     --list-entity
  * Mostrar informações sobre uma entidade:
     --list-entity=<id_entidade>
  * Mostrar entidades de uma categoria:
     --list-entity --category=<id_categoria>

- Controle de Interface
  * Adicionar interface:
     --add-interface=<interface>
  * Remover interface:
     --del-interface=<interface>
  * Mostrar todas interfaces:
     --list-interface

- Controle de Autorização
  * Conceder autorização:
     --set-authorization=<id_membro> --grant=<interface>
  * Revogar autorização:
     --set-authorization=<id_membro> --revoke=<interface>
  * Mostrar todas as autorizações:
     --list-authorization
  * Mostrar autorizações do membro:
     --list-authorization=<id_membro>
  * Mostrar todas autorizações contendo as interfaces:
     --list-authorization --interface="<iface1> <iface2> ... <ifaceN>"

- Controle de Ofertas no Serviço de Registro
  * Remover oferta:
     --del-offer=<id_oferta>
  * Mostrar todas interfaces ofertadas:
     --list-offer
  * Mostrar todas interfaces ofertadas por um membro:
     --list-offer=<id_membro>

- Controle de Logins
  * Remove um login
     --del-login=<id_login>
  * Mostrar todas interfaces ofertadas:
     --list-login
  * Mostrar todas interfaces ofertadas por um membro:
     --list-login --entity=<id_entidade>

- Script
  * Executa script Lua com um lote de comandos:
     --script=<arquivo>
  * Desfaz a execução de um script Lua com um lote de comandos:
    --undo-script=<arquivo>
-------------------------------------------------------------------------------
]]

-------------------------------------------------------------------------------
-- Define o parser da linha de comando.
--

-- Este valor é usado como uma constante para valor de comando ou parâmetro.
local null = {}

--
-- Valor padrão das opções. Caso a linha de comando não informe, estes valores
-- serão copiados para a tabela de linha de comando.
--
local options = {
  ["host"] = "127.0.0.1",
  ["port"] = 2089,
  oilVerbose   = 0,
  verbose      = 0,
}

--
-- Lista de comandos que são aceitos pelo programa.
--
-- Cada comando pode aceitar diferentes parâmetros. Esta ferramenta de parser
-- verifica se a linha de comando informada casa com os parâmetros
-- mínimos que o comando espera. Se forem passados mais parâmetros que
-- o necessário, a ferramenta ignora.
--
-- O casamento é feito na seqüência que ele é descrito. A ferramenta retorna
-- ao encontrar a primeira forma válida.
--
-- Se a variável 'n' for 1, isso indica que o próprio comando precisa
-- de um parâmetro, ou seja, formato '--command=val'. Se 'n' for 0, então o
-- comando é da forma '--command'.
--
-- O campo 'params' indica o nome dos parâmetros esperados e se eles têm valor
-- ou não, isto é, se eles seguem a forma do comando descrito acima:
--   --parameter=value
--   --parameter
--
-- Após o parser, os parâmetros e comandos que foram informados no
-- formato '--command' terão valor igual a 'null', inidicando que eles
-- estão presentes, mas sem valor.
--
-- Parâmetros não informados terão valor 'nil'. (comandos sempre devem
-- ser informados e nunca são nil)
--

local commands = {
  help = {
    --help
    {n = 0, params = {}}
  };
  ["add-category"] = {
    {n = 1, params = {name = 1}}
  };
  ["del-category"] = {
    {n = 1, params = {}}
  };
  ["set-category"] = {
    {n = 1, params = {name = 1}},
  };
  ["list-category"] = {
    {n = 0, params = {}},
    {n = 1, params = {}},
  };
  ["add-entity"] = {
    {n = 1, params = {category = 1, name = 1}}
  };
  ["del-entity"] = {
    {n = 1, params = {}}
  };
  ["set-entity"] = {
    {n = 1, params = {name = 1}}
   };
  ["list-entity"] = {
    {n = 0, params = {category = 1}},
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
    {n = 1, params={grant = 1}},
    {n = 1, params={revoke = 1}},
  };
  ["del-authorization"] = {
    {n = 1, params = {force = 0}},
    {n = 1, params = {}}
  };
  ["list-authorization"] = {
    {n = 0, params = {}},
    {n = 1, params = {interface = 1}},
    {n = 1, params = {}},
  };
  ["del-login"] = {
    {n = 1, params = {}},
  };
  ["list-login"] = {
    {n = 0, params = {entity = 1}},
    {n = 0, params = {}},
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
-- Se um parâmetro não possui valor informado, utilizamos um marcador único
-- 'null' em vez de nil, para indicar ausência. Isso diferencia o fato
-- do parâmetro não ter valor de ele não ter sido informado (neste caso, nil).
--
-- @param argv Uma tabela com os parâmetros da linha de comando.
--
-- @return Uma tabela onde a chave é o nome do parâmetro. Em caso de erro,
-- é retornado nil, seguido de uma mensagem.
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
        return nil, string.format("Parâmetro inválido: %s", param)
      end
    end
  end
  return line
end

---
-- Verifica se as opções foram informadas e completa os valores ausentes.
--
-- @para params Os parâmetros extraídos da linha de comando.
--
-- @return true se as opções foram inseridas com sucesso. No caso de
-- erro, retorna false e uma mensagem.
--
local function addoptions(params)
  for opt, val in pairs(options) do
    if not params[opt] then
      params[opt] = val
    elseif params[opt] == null then
      return false, string.format("Opção inválida: %s", opt)
    end
  end
  return true
end

---
-- Verifica na a tabela de parâmetros possui um, e apenas um, comando.
--
-- @param params Parâmetros extraídos da linha de comando.
--
-- @return Em caso de sucesso, retorna o nome do comando, seu valor de
-- linha de comando e sua descrição na tabela geral de comandos. No caso
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
  return nil, "Comando inválido"
end

---
-- Realiza o parser da linha de comando.
--
-- @param argv Array com a linha de comando.
--
-- @return Tabela com os campos 'command' contendo o nome do comando
-- e 'params' os parâmetros vindos da linha de comando.
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
  -- Verifica se os parâmetros necessários existem e identifica
  -- qual o string.formato do comando se refere.
  local found
  for _, desc in ipairs(cmddesc) do
    -- O comando possui valor?
    if (desc.n == 1 and cmdval ~= null) or
       (desc.n == 0 and cmdval == null)
    then
      found = desc
      -- Os parâmetros existem e possuem valor?
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
    return nil, "Parâmetros inválidos"
  end
  return {
    name = cmdname,
    params = params,
  }
end

-------------------------------------------------------------------------------
-- Funções auxiliares

---
-- Função auxiliar para imprimir string formatada.
--
-- @param str String a ser formatada e impressa.
-- @param ... Argumentos para formatar a string.
--
local function printf(str, ...)
  print(string.format(str, ...))
end

---
-- Testa se o identificar de sistema e implantação possuem um formato válido.
--
-- @param id Identificador
-- @return true se ele possui um formato válido, false caso contrário
--
local function validId(id)
  return (string.match(id, "^[_a-zA-Z0-9]+$") ~= nil)
end

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
handlers["add-category"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  if validId(id) then
    conn.EntityRegistry:createEntityCategory(id, cmd.params.name)
  else
    printf("[ERRO] Falha ao adicionar sistema '%s': " ..
           "identificador inválido", id)
  end
  print(string.format("[INFO] Categoria '%s' cadastrada com sucesso", id))
end

---
-- Remove um sistema do barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-category"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local category = conn.EntityRegistry:getEntityCategory(id)
  category:remove()
  print(string.format("[INFO] Categoria '%s' removida com sucesso", id))
end

---
-- Altera informações da categoria.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-category"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local category = conn.EntityRegistry:getEntityCategory(cmd.params[cmd.name])
  category:setName(cmd.params.name)
  print(string.format("[INFO] Categoria '%s' atualizada com sucesso", id))
end

---
-- Exibe informações sobre as categorias.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-category"] = function(cmd)
  local categories
  local conn = connect()
  -- Busca todas
  if cmd.params[cmd.name] == null then
    categories = conn.EntityRegistry:getEntityCategories()
  else
    -- Busca uma categoria específica
    local category = conn.EntityRegistry:getEntityCategory(cmd.params[cmd.name])
    categories = {category:describe()}
  end
  printer.showCategory(categories)
end

---
-- Adiciona uma nova entidade.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-entity"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  if not validId(id) then
    printf("[ERRO] Falha ao adicionar implantação '%s': " ..
           "identificador inválido", id)
    return
  end
  local category = conn.EntityRegistry:getEntityCategory(cmd.params.category)
  category:registerEntity(id, cmd.params.name)
  printf("[INFO] Entidade '%s' cadastrada com sucesso", id)
end

---
-- Remove uma entidade.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-entity"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local entity = conn.EntityRegistry:getEntity(id)
  entity:remove()
  printf("[INFO] Entidade '%s' removida com sucesso", id)
end

---
-- Altera informações da entidade.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-entity"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local entity = conn.EntityRegistry:getEntity(id)
  entity:setName(cmd.params.name)
  printf("[INFO] Entidade '%s' atualizada com sucesso", id)
end

---
-- Exibe informações das entidades.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-entity"] = function(cmd)
  local entities
  local conn = connect()
  local id = cmd.params[cmd.name]
  local category = cmd.params.category
  if id == null then
    -- TODO: possivelmente, a verficacao category == null é um bug
    if not category or category == null then
      -- Busca todos
      entities = conn.EntityRegistry:getEntities()
    else
      -- Filtra por categoria
      local category = conn.EntityRegistry:getEntityCategory(category)
      entities = category:getEntities()
    end
  else
    -- Busca apenas uma implantação
    local entity = conn.EntityRegistry:getEntity(id)
    if entity ~= nil then 
      entities = {entity:describe()}
    end
  end
  printer.showEntity(entities)
end

---
-- Adiciona um nova interface.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-interface"] = function(cmd)
  print("NOT IMPLEMENTED!")
end

---
-- Remove uma interface.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-interface"] = function(cmd)
  print("NOT IMPLEMENTED!")
end

---
-- Exibe as interfaces cadastradas.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-interface"] = function(cmd)
  print("NOT IMPLEMENTED!")
end

---
-- Altera a autorização de um membro do barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-authorization"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local entity = conn.EntityRegistry:getEntity(id)
  local interface
  if cmd.params.grant then
    -- Concede uma autorização
    interface = cmd.params.grant
    entity:addAuthorization(interface)
    printf("[INFO] Autorização concedida a '%s': %s", id, interface)
  else
    -- Revoga autorização
    interface = cmd.params.revoke
    entity:removeAuthorization(interface)
   printf("[INFO] Autorização revogada de '%s': %s", id, interface)
  end
end

---
-- Exibe as autorizações.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-authorization"] = function(cmd)
  local auths = {}
  local conn = connect()
  local id = cmd.params[cmd.name]
  if id == null then
    if not cmd.params.interface or cmd.params.interface == null then
      -- Busca todas
      local ents = conn.EntityRegistry:getAuthorizedEntities()
      for _, entitydesc in ipairs(ents) do 
        local authorization = {}
        authorization.id = entitydesc.id
        authorization.interfaces = entitydesc.ref:getAuthorizationSpecs()
        table.insert(auths, authorization)
      end
    else
      -- Filtra por interfaces
      local ifaces = {}
      for iface in string.gmatch(cmd.params.interface, "%S+") do
        ifaces[#ifaces+1] = iface
      end
      local ents = conn.EntityRegistry:getEntitiesByAuthorizedInterfaces(ifaces)
      for _, entitydesc in ipairs(ents) do 
        local authorization = {}
        authorization.id = entitydesc.id
        authorization.interfaces = entitydesc.ref:getAuthorizationSpecs()
        table.insert(auths, authorization)
      end
    end
  else
    -- Busca por entidade
    local entity = conn.EntityRegistry:getEntity(id)
    local authorization = {}
    authorization.id = id
    authorization.interfaces = entity:getAuthorizationSpecs()
    table.insert(auths, authorization)
  end
  printer.showAuthorization(auths)
end

---
-- Remove o login.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-login"] = function(cmd)
  local logins
  local conn = connect()
  local id = cmd.params[cmd.name]
  conn.LoginRegistry:terminateLogin(id)
  printf("[INFO] Login '%s' removido com sucesso.", id)
end

---
-- Exibe os logins.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-login"] = function(cmd)
  local logins
  local conn = connect()
  if not cmd.params.entity or cmd.params.entity == null then
    -- Busca todos
    logins = conn.LoginRegistry:getAllLogins()
  else
    -- Filtra por entidade
    logins = conn.LoginRegistry:getEntityLogins(cmd.params.entity)
  end
  -- remove o próprio login da lista
  local index
  for i,login in ipairs(logins) do
    if login.id == conn.login.id then
      index = i
    end
  end
  if index then 
    table.remove(logins, index)
  end
  printer.showLogin(logins)
end

---
-- Exibe as ofertas cadastradas.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-offer"] = function(cmd)
  print("NOT IMPLEMENTED!")
end

---
-- Remove a oferta cadastrada.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-offer"] = function(cmd)
  print("NOT IMPLEMENTED!")
end

---
-- Carrega e executa um script Lua para lote de comandos
--
-- @param cmd Comando e seus argumentos.
--
handlers["script"] = function(cmd)
  print("NOT IMPLEMENTED!")
end

---
-- Carrega e desfaz um script Lua para lote de comandos
--
-- @param cmd Comando e seus argumentos.
--
handlers["undo-script"] = function(cmd)
  print("NOT IMPLEMENTED!")
end

-------------------------------------------------------------------------------
-- Seção de conexão com o barramento e os serviços básicos

---
-- Efetua a conexão com o barramento.
--
-- @param retry Parâmetro opcional que indica o número da tentativa de
-- reconexão.
---
function connect(retry)
  if connection ~= nil then 
    return connection
  end
  --TODO: implementar mecanismo de retry.
  local conn = openbus.connectByAddress(host, port, nil, log)
  local localPassword = password
  if not localPassword then
    localPassword = lpw.getpass("Senha: ")
  end
  local status, err = pcall(conn.loginByPassword, conn, login, localPassword)
  if not status then
    print("[ERRO] Falha no Login.")
    log:warn(err)
    os.exit(1)
  end
  connection = conn
  return connection
end

-------------------------------------------------------------------------------
-- Função Principal
--

-- Faz o parser da linha de comando.
-- Verifica se houve erro e já despacha o comando de ajuda para evitar
-- a conexão com os serviços do barramento
local command, msg = parse{...}
if not command then
  print("[ERRO] " .. msg)
  print("[HINT] --help")
  os.exit(1)
elseif command.name == "help" then
  handlers.help(command)
  os.exit(1)
elseif not command.params.login then
  print("[ERRO] Usuário não informado")
  os.exit(1)
end

-- Recupera os valores globais
login    = command.params.login
password = command.params.password
host  = command.params["host"]
port  = tonumber(command.params["port"])

oil.verbose:level(tonumber(command.params.oilVerbose))
log:level(tonumber(command.params.verbose))

---
-- Função principal responsável por despachar o comando.
--
local function main()
  local f = handlers[command.name]
  if f then
    f(command)
  end
  --
  if connection ~= nil and connection:isLoggedIn() then
    connection:logout()
    connection = nil
  end
  os.exit()
end

oil.main(function()
  print(pcall(main))
end)
