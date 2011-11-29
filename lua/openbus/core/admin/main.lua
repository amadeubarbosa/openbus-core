local _G = require "_G"
local next  = _G.next
local pairs = _G.pairs
local ipairs = _G.ipairs
local string = _G.string
local print = _G.print
local io = _G.io
local pcall = _G.pcall
local error = _G.error

local oil = require "oil"
local oillog = require "oil.verbose"

local lpw = require "lpw"

local openbus = require "openbus"
local log = require "openbus.util.logger"
local server = require "openbus.util.server"
local setuplog = server.setuplog
local printer = require "openbus.core.admin.print"
local script = require "openbus.core.admin.script"
local msg = require "openbus.core.admin.messages"
local idl = require "openbus.core.idl"
local logintypes = idl.types.services.access_control
local offertypes = idl.types.services.offer_registry

-- Alias
local lower = _G.string.lower

-- Vari�veis que s�o referenciadas antes de sua cri��o
-- N�o usar globais para n�o export�-las para o comando 'script'
local login, password
local host, port
local connection

-- Guarda as fun��es que ser�o os tratadores das a��es de linha de comando
local handlers = {}

-- Nome do script principal (usado no help)
local program = OPENBUS_PROGNAME

-------------------------------------------------------------------------------
-- Constantes

-- Maximo de tentativas de conex�o com o barramento
local MAXRETRIES = 3

-- String de help
local help = [[

Uso: %s [op��es] --login=<usu�rio> <comando>

-------------------------------------------------------------------------------
- Op��es
  * Informa o endere�o do Barramento (padr�o 127.0.0.1):
    --host=<endere�o>
  * Informa a porta do Barramento (padr�o 2089):
    --port=<porta>
  * Aciona o verbose da API Openbus.
    --verbose=<level>
  * Aciona o verbose do OiL.
    --oilverbose=<level>
    
- Controle de Categoria
  * Adicionar categoria:
     --add-category=<id_categoria> --name=<nome>
  * Remover categoria:
     --del-category=<id_categoria>
  * Alterar o nome descritivo da categoria:
     --set-category=<id_categoria> --name=<nome>
  * Mostrar todas as categorias:
     --list-category
  * Mostrar informa��es sobre uma categoria:
     --list-category=<id_categoria>

- Controle de Entidade
  * Adicionar entidade:
     --add-entity=<id_entidade> --category<id_categoria> --name=<nome>
  * Alterar descri��o:
     --set-entity=<id_entidade> --name=<nome>
  * Remover entidade:
     --del-entity=<id_entidade>
  * Mostrar todas as entidades:
     --list-entity
  * Mostrar informa��es sobre uma entidade:
     --list-entity=<id_entidade>
  * Mostrar entidades de uma categoria:
     --list-entity --category=<id_categoria>

- Controle de Certificado
  * Adiciona certificado da entidade:
    --add-certificate=<id_entidade> --certificate=<certificado>
  * Remover certificado da entidade:
    --del-certificate=<id_entidade>
     
- Controle de Interface
  * Adicionar interface:
     --add-interface=<interface>
  * Remover interface:
     --del-interface=<interface>
  * Mostrar todas interfaces:
     --list-interface

- Controle de Autoriza��o
  * Conceder autoriza��o:
     --set-authorization=<id_entidade> --grant=<interface>
  * Revogar autoriza��o:
     --set-authorization=<id_entidade> --revoke=<interface>
  * Mostrar todas as autoriza��es:
     --list-authorization
  * Mostrar autoriza��es da entidade:
     --list-authorization=<id_entidade>
  * Mostrar todas autoriza��es contendo as interfaces:
     --list-authorization --interface="<iface1> <iface2> ... <ifaceN>"

- Controle de Ofertas no Servi�o de Registro
  * Remover oferta (lista e aguarda a entrada de um �ndice para remover a oferta):
    --del-offer
  * Remover oferta da entidade (lista e aguarda a entrada de um �ndice para remover a oferta):
    --del-offer --entity=<id_entidade>
  * Mostrar todas interfaces ofertadas:
     --list-offer
  * Mostrar todas interfaces ofertadas por uma entidade:
     --list-offer=<id_entidade>

- Controle de Logins
  * Remove um login:
     --del-login=<id_login>
  * Mostrar todos os logins:
     --list-login
  * Mostrar todos os logins de uma entidade:
     --list-login --entity=<id_entidade>

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
  ["host"] = "127.0.0.1",
  ["port"] = 2089,
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
    {n = 1, params = {category = 1, name = 1}},
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
  ["add-certificate"] = {
    {n = 1, params = {certificate = 1}}
   };
  ["del-certificate"] = {
    {n = 1, params = {}}
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
    {n = 0, params = {}},
    {n = 1, params = {}},
  };
  ["del-offer"] = {
    {n = 0, params = {}},
    {n = 0, params = {entity = 1}},
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
      found = desc
      -- Os par�metros existem e possuem valor?
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
-- Define os tratadores de comandos passados como argumento para a ferramenta.
--

---
-- Exibe o menu de ajuda da ferramenta.
--
-- @param cmd Comando e seus argumentos.
--
handlers["help"] = function(cmd)
  printf(help, program)
  return true
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
    local ok, err = pcall(conn.entities.createEntityCategory, conn.entities,
        id, cmd.params.name)
    if not ok then
      if err._repid == offertypes.EntityCategoryAlreadyExists then
        printf("[ERRO] Categoria '%s' j� cadastrada", id)
      else
        error(err)
      end
      return false
    end
  else
    printf("[ERRO] Falha ao adicionar categoria '%s': " ..
           "identificador inv�lido", id)
    return false
  end
  printf("[INFO] Categoria '%s' cadastrada com sucesso", id)
  return true
end

---
-- Remove um sistema do barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-category"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local category = conn.entities:getEntityCategory(id)
  if not category then 
    printf("[ERRO] Categoria '%s' n�o existe.", id)
    return false
  end
  local ok, err = pcall(category.remove, category)
  if not ok then
    if err._repid == offertypes.EntityCategoryInUse then
      printf("[ERRO] Categoria '%s' em uso.", id)
    else
      error(err)
    end
    return false
  end
  printf("[INFO] Categoria '%s' removida com sucesso", id)
  return true
end

---
-- Altera informa��es da categoria.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-category"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local category = conn.entities:getEntityCategory(cmd.params[cmd.name])
  if not category then 
    printf("[ERRO] Categoria '%s' n�o existe.", id)
    return false
  end
  category:setName(cmd.params.name)  
  printf("[INFO] Categoria '%s' atualizada com sucesso", id)
  return true
end

---
-- Exibe informa��es sobre as categorias.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-category"] = function(cmd)
  local categories
  local conn = connect()
  -- Busca todas
  if cmd.params[cmd.name] == null then
    categories = conn.entities:getEntityCategories()
  else
    -- Busca uma categoria espec�fica
    local category = conn.entities:getEntityCategory(cmd.params[cmd.name])
    if not category then 
      printf("[ERRO] Categoria '%s' n�o existe.", id)
      return false
    end
    categories = {category:describe()}
  end
  printer.showCategory(categories)
  return true
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
    printf("[ERRO] Falha ao adicionar entidade '%s': " ..
           "identificador inv�lido", id)
    return false
  end

  local category = conn.entities:getEntityCategory(cmd.params.category)
  if not category then 
    printf("[ERRO] Categoria '%s' n�o existe.", id)
    return false
  end
  local ok, err = pcall(category.registerEntity, category, id, cmd.params.name)
  if not ok then
    if err._repid == offertypes.EntityAlreadyRegistered then
      printf("[ERRO] Entidade '%s' j� cadastrada.", id)
    else
      error(err)
    end
    return false
  end
  printf("[INFO] Entidade '%s' cadastrada com sucesso", id)
  return true
end

---
-- Remove uma entidade.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-entity"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local entity = conn.entities:getEntity(id)
  if not entity then
    printf("[ERRO] Entidade '%s' inexistente.", id)
    return false
  end
  entity:remove()
  -- se tiver certificado, remove
  conn.certificates:removeCertificate(id)
  printf("[INFO] Entidade '%s' removida com sucesso", id)
  return true
end

---
-- Altera informa��es da entidade.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-entity"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local entity = conn.entities:getEntity(id)
  if not entity then
    printf("[ERRO] Entidade '%s' n�o existe.", id)
    return false
  end
  entity:setName(cmd.params.name)
  printf("[INFO] Entidade '%s' atualizada com sucesso", id)
  return true
end

---
-- Exibe informa��es das entidades.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-entity"] = function(cmd)
  local entities
  local conn = connect()
  local id = cmd.params[cmd.name]
  local category = cmd.params.category
  if id == null then
    -- TODO: possivelmente, a verficacao category == null � um bug
    if not category or category == null then
      -- Busca todos
      entities = conn.entities:getEntities()
    else
      -- Filtra por categoria
      local category = conn.entities:getEntityCategory(category)
      if not category then 
        printf("[ERRO] Categoria '%s' n�o existe.", category)
        return false
      end
      entities = category:getEntities()
    end
  else
    -- Busca apenas uma implanta��o
    local entity = conn.entities:getEntity(id)
    if not entity then
      printf("[ERRO] Entidade '%s' n�o existe.", id)
      return false
    else 
      entities = {entity:describe()}
    end
  end
  printer.showEntity(entities)
  return true
end

---
-- Adiciona um certificado.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-certificate"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  if not validId(id) then
    printf("[ERRO] Falha ao adicionar certificado '%s': " ..
           "identificador inv�lido", id)
    return false
  end
  
  local certificate = cmd.params.certificate
  local f = io.open(certificate)
  if not f then
    print("[ERRO] N�o foi poss�vel localizar arquivo de certificado")
    return false
  end
  local cert = f:read("*a")
  if not cert then
    print("[ERRO] N�o foi poss�vel ler o certificado")
    return false
  end
  local ok, err = pcall(conn.certificates.registerCertificate,
      conn.certificates, id, cert)
  if not ok then
    if err._repid == logintypes.InvalidCertificate then
      printf("[ERRO] Certificado inv�lido: '%s'", certificate)
    else
      error(err)
    end
    return false
  end
  printf("[INFO] Certificado da entidade '%s' cadastrada com sucesso", id)
  return true
end

---
-- Remove um certificado.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-certificate"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local ret = conn.certificates:removeCertificate(id)
  if ret then
    printf("[INFO] Certificado da entidade '%s' removido com sucesso", id)
  else
    printf("[INFO] Certificado da entidade '%s' n�o existe", id)
  end
  return ret
end

---
-- Adiciona um nova interface.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-interface"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local ok, err = pcall(conn.interfaces.registerInterface, conn.interfaces, id)
  if not ok then
    if err._repid == offertypes.InvalidInterface then
      printf("[ERRO] Interface '%s' inv�lida.", id)
    else
      error(err)
    end
    return false
  end
  printf("[INFO] Interface '%s' cadastrada com sucesso.", id)
  return true
end

---
-- Remove uma interface.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-interface"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local ok, err = pcall(conn.interfaces.removeInterface, conn.interfaces, id)
  if not ok then
    if err._repid == offertypes.InterfaceInUse then
      printf("[ERRO] Interface '%s' em uso.", id)
    else
      error(err)
    end
    return false
  end
  printf("[INFO] Interface '%s' removida com sucesso.", id)
  return true
end

---
-- Exibe as interfaces cadastradas.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-interface"] = function(cmd)
  local conn = connect()
  local interfaces = conn.interfaces:getInterfaces()
  printer.showInterface(interfaces)
  return true
end

---
-- Altera a autoriza��o de um membro do barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-authorization"] = function(cmd)
  local conn = connect()
  local id = cmd.params[cmd.name]
  local entity = conn.entities:getEntity(id)
  if not entity then
    printf("[ERRO] Entidade '%s' n�o existe.", id)
    return false
  end
  local interface
  local ok, err
  if cmd.params.grant then
    -- Concede uma autoriza��o
    interface = cmd.params.grant
    ok, err = pcall(entity.grantInterface, entity, interface)
    if not ok then
      if err._repid == offertypes.InvalidInterface then
        printf("[ERRO] Interface '%s' inv�lida.", interface)
      else
        error(err)
      end
      return false
    end
    printf("[INFO] Autoriza��o concedida a '%s': %s", id, interface)
  else
    -- Revoga autoriza��o
    interface = cmd.params.revoke
    ok, err = pcall(entity.revokeInterface, entity, interface)
    if not ok then
      if err._repid == offertypes.InvalidInterface then
        printf("[ERRO] Interface '%s' inv�lida.", interface)
      elseif err._repid == offertypes.AuthorizationInUse then
        printf("[ERRO] Autoriza��o '%s' em uso pela entidade '%s'.", interface,
          id)
      else
        error(err)
      end
      return false
    end
    printf("[INFO] Autoriza��o revogada de '%s': %s", id, interface)
  end
  return true
end

---
-- Exibe as autoriza��es.
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
      local ents = conn.entities:getAuthorizedEntities()
      for _, entitydesc in ipairs(ents) do 
        local authorization = {}
        authorization.id = entitydesc.id
        authorization.interfaces = entitydesc.ref:getGrantedInterfaces()
        table.insert(auths, authorization)
      end
    else
      -- Filtra por interfaces
      local ifaces = {}
      for iface in string.gmatch(cmd.params.interface, "%S+") do
        ifaces[#ifaces+1] = iface
      end
      local ents = conn.entities:getEntitiesByAuthorizedInterfaces(ifaces)
      for _, entitydesc in ipairs(ents) do 
        local authorization = {}
        authorization.id = entitydesc.id
        authorization.interfaces = entitydesc.ref:getGrantedInterfaces()
        table.insert(auths, authorization)
      end
    end
  else
    -- Busca por entidade
    local entity = conn.entities:getEntity(id)
    if not entity then
      printf("[ERRO] Entidade '%s' n�o existe.", id)
      return false
    end
    local authorization = {}
    authorization.id = id
    authorization.interfaces = entity:getGrantedInterfaces()
    table.insert(auths, authorization)
  end
  printer.showAuthorization(auths)
  return true
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
  conn.logins:invalidateLogin(id)
  printf("[INFO] Login '%s' removido com sucesso.", id)
  return true
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
    logins = conn.logins:getAllLogins()
  else
    -- Filtra por entidade
    logins = conn.logins:getEntityLogins(cmd.params.entity)
  end
  -- remove o pr�prio login da lista
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
  return true
end

---
-- Exibe as ofertas cadastradas.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-offer"] = function(cmd)
  local offers
  local conn = connect()
  local id = cmd.params[cmd.name]
  if id == null then 
    -- Lista todos
    offers = conn.offers:getServices()
  else
    -- Filtra por entidade
    offers = conn.offers:findServices({{name="openbus.offer.entity",value=id}})
  end
  printer.showOffer(offers)
  return true
end

---
-- Remove a oferta cadastrada.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-offer"] = function(cmd)
  local conn = connect()
  offers = conn.offers:getServices()
  local descs = printer.showOffer(offers)
  print("Informe o �ndice da oferta que deseja remover:")
  local id = tonumber(io.read())
  if id ~= nil and descs[id] ~= nil then
    for key, value in pairs (descs[id]) do
      if key == "id" and value == id then
        descs[id].offer:remove()
      end
    end
  else
    printf("[ERRO] �ndice de oferta inv�lido: '%d'", id)
    return false
  end
  printf("[INFO] Oferta '%d' removida com sucesso.", id)
  return true
end

---
-- Carrega e executa um script Lua para lote de comandos
--
-- @param cmd Comando e seus argumentos.
--
handlers["script"] = function(cmd)
  script.setup(handlers)
  return script.doScript(cmd)
end

---
-- Carrega e desfaz um script Lua para lote de comandos
--
-- @param cmd Comando e seus argumentos.
--
handlers["undo-script"] = function(cmd)
  script.setup(handlers)
  return script.undoScript(cmd)
end

-------------------------------------------------------------------------------
-- Se��o de conex�o com o barramento e os servi�os b�sicos

---
-- Efetua a conex�o com o barramento.
--
-- @param retry Par�metro opcional que indica o n�mero da tentativa de
-- reconex�o.
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
  local ok, err = pcall(conn.loginByPassword, conn, login, localPassword)
  if not ok then
    print("[ERRO] Falha no Login!")
    if err._repid == logintypes.AccessDenied then
      log:failure(msg.AccessDeniedOnLogin)
    elseif err._repid == logintypes.WrongEncoding then
      log:failure(msg.WrongEncodedPassword)
    else 
      error(err)
    end
    return 1
  end
  connection = conn
  return connection
end

-------------------------------------------------------------------------------
-- Fun��o Principal
--

-- Faz o parser da linha de comando.
-- Verifica se houve erro e j� despacha o comando de ajuda para evitar
-- a conex�o com os servi�os do barramento
return function(...)
  local command, msg = parse{...}
  if not command then
    print("[ERRO] " .. msg)
    print("[HINT] --help")
    return 1
  elseif command.name == "help" then
    handlers.help(command)
    return 0
  elseif not command.params.login then
    print("[ERRO] Usu�rio n�o informado")
    return 1
  end

  -- Recupera os valores globais
  login    = command.params.login
  password = command.params.password
  host  = command.params["host"]
  port  = tonumber(command.params["port"])

  -- setup log files
  local loglevel = tonumber(command.params.verbose) or 0
  setuplog(log, loglevel)
  local oillevel = tonumber(command.params.oilverbose) or 0
  setuplog(oillog, oillevel)

  ---
  -- Fun��o principal respons�vel por despachar o comando.
  --
  local function main()
    local f = handlers[command.name]
    local returned
    if f then
      returned = f(command)
    end
    --
    if connection ~= nil and connection:isLoggedIn() then
      connection:logout()
      connection = nil
    end
    if returned then
      return 0
    else
      return 1
    end
  end

  local ok, ret = pcall(main)
  if not ok then
    print(ret)
  end
  return ret
end
