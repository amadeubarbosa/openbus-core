-------------------------------------i------------------------------------------
-- Função Principal
--
return function(...)
  local _G = require "_G"
  local error = _G.error
  local ipairs = _G.ipairs
  local next  = _G.next
  local pairs = _G.pairs
  local pcall = _G.pcall
  local print = _G.print
  local string = _G.string
  local tostring = _G.tostring

  local io = require "io"
  local os = require "os"

  local oil = require "oil"
  local oillog = require "oil.verbose"

  local lpw = require "lpw"

  local openbus = require "openbus"
  local log = require "openbus.util.logger"
  local access = require "openbus.core.Access"
  local neworb = access.initORB
  local idl = require "openbus.core.idl"
  local BusObjectKey = idl.const.BusObjectKey
  local types = idl.types.services
  local logintypes = idl.types.services.access_control
  local idl = require "openbus.core.admin.idl"
  local admintypes = idl.types.services.access_control.admin.v1_0
  local authotypes = idl.types.services.offer_registry.admin.v1_0
  local printer = require "openbus.core.admin.print"
  local script = require "openbus.core.admin.script"
  local messages = require "openbus.core.admin.messages"

  -- Alias
  local lower = _G.string.lower

  -- Variáveis que são referenciadas antes de sua crição
  -- Não usar globais para não exportá-las para o comando 'script'
  local login, password
  local host, port
  local connection
  local orb = openbus.initORB{ localrefs="proxy" }
  local OpenBusContext = orb.OpenBusContext
  do
    idl.loadto(orb)
    local CoreServices = {
      CertificateRegistry = admintypes,
      InterfaceRegistry = authotypes,
      EntityRegistry = authotypes,
    }
    for name, idlmod in pairs(CoreServices) do
      OpenBusContext["get"..name] = function (self)
        local conn = self:getCurrentConnection()
        if conn == nil or conn.login == nil then
          sysexthrow.NO_PERMISSION{
            completed = "COMPLETED_NO",
            minor = loginconst.NoLoginCode,
          }
        end
        return self.orb:narrow(conn.bus:getFacetByName(name), idlmod[name])
      end
    end
  end

  -- Guarda as funções que serão os tratadores das ações de linha de comando
  local handlers = {}

  -- Nome do script principal (usado no help)
  local program = OPENBUS_PROGNAME

  -------------------------------------------------------------------------------
  -- Constantes

  -- String de help
  local help = [[

  Uso: %s [opções] --login=<usuário> <comando>

  Por padrão realiza-se um login por senha. Vide opção '--password'

  -------------------------------------------------------------------------------
  - Opções
    * Informa o endereço do Barramento (padrão 127.0.0.1):
      --host=<endereço>
    * Informa a porta do Barramento (padrão 2089):
      --port=<porta>
    * Realiza o login por senha, aguardando a entrada da senha por linha de comando.
      --password
    * Realiza o login por senha.
      --password=<password>
    * Realiza o login com chave privada.
      --privatekey=<private key>
    * Aciona o verbose da API OpenBus.
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
    * Mostrar informações sobre uma categoria:
       --list-category=<id_categoria>

  - Controle de Entidade
    * Adicionar entidade:
       --add-entity=<id_entidade> --category=<id_categoria> --name=<nome>
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

  - Controle de Certificado
    * Adiciona certificado da entidade:
      --add-certificate=<id_entidade> --certificate=<certificado>
    * Remover certificado da entidade:
      --del-certificate=<id_entidade>
    * Mostrar entidades com um certificado cadastrado:
      --list-certificate
       
  - Controle de Interface
    * Adicionar interface:
       --add-interface=<interface>
    * Remover interface:
       --del-interface=<interface>
    * Mostrar todas interfaces:
       --list-interface

  - Controle de Autorização
    * Conceder autorização:
       --set-authorization=<id_entidade> --grant=<interface>
    * Revogar autorização:
       --set-authorization=<id_entidade> --revoke=<interface>
    * Mostrar todas as autorizações:
       --list-authorization
    * Mostrar autorizações da entidade:
       --list-authorization=<id_entidade>
    * Mostrar todas autorizações contendo as interfaces:
       --list-authorization --interface="<iface1> <iface2> ... <ifaceN>"

  - Controle de Ofertas no Serviço de Registro
    * Remover oferta (lista e aguarda a entrada de um índice para remover a oferta):
      --del-offer
    * Remover oferta da entidade (lista e aguarda a entrada de um índice para remover a oferta):
      --del-offer --entity=<id_entidade>
    * Mostrar todas interfaces ofertadas:
       --list-offer
    * Mostrar todas interfaces ofertadas por uma entidade:
       --list-offer=<id_entidade>
    * Mostrar as propriedades da oferta (lista e aguarda a entrada de um índice para listar propriedades da oferta):
       --list-props
    * Mostrar as propriedades da oferta por uma entidade (lista e aguarda a entrada de um índice para listar propriedades da oferta):
       --list-props=<id_entidade>

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
    * Desfaz a execução de um script Lua com um lote de comandos:
      --undo-script=<arquivo>

  - Manutenção
    * Encerra a execução atual do barramento:
      --shutown
    * Monta um relatório sobre o estado atual do barramento:
      --report
  
  - Configuração
    * Recarrega o arquivo de configurações do barramento:
      --reload-configs-file
    * Atribui os privilégios de administração para uma lista de usuários:
      --grant-admin-to="<user1> <user2> ... <userN>"
    * Revoga os privilégios de administração para uma lista de usuários:
      --revoke-admin-from="<user1> <user2> ... <userN>"
    * Mostra a lista de administradores:
      --get-admins
    * Recarrega um validador de login. Se o não existir o validador é carregado:
      --reload-validator=<validator>
    * Remove um validador de login:
      --del-validator=<validator>
    * Mostra a lista de validadores:
      --get-validators
    * Redefine o número máximo de canais de comunicação do OiL:
      --set-max-channels=<integer>
    * Mostra o número máximo de canais de comunicação do OiL:
      --get-max-channels
    * Redefine o nível de log do barramento:
      --set-log-level=<integer>
    * Mostra o nível de log do barramento:
      --get-log-level
    * Redefine o nível de log do OiL.
      --set-oil-log-level=<integer>
    * Mostra o nível de log do OiL:
      --get-oil-log-level
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
    oilverbose = 0,
    verbose = 0,
    password = null,
    privatekey = null,
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
    ["list-certificate"] = {
      {n = 0, params = {}}
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
    ["list-props"] = {
      {n = 0, params = {}},
      {n = 0, params = {entity = 1}},
    };
    ["script"] = {
      {n = 1, params = {}},
    };
    ["undo-script"] = {
      {n = 1, params = {}},
    };
    ["shutdown"] = {
      {n = 0, params = {}}
    };
    ["report"] = {
      {n = 0, params = {}}
    };
    ["reload-configs-file"] = {
      {n = 0, params = {}}
    };
    ["grant-admin-to"] = {
      {n = 0, params = {}},
      {n = 1, params = {users = 1}},
      {n = 1, params = {}},
    };
    ["revoke-admin-from"] = {
      {n = 0, params = {}},
      {n = 1, params = {users = 1}},
      {n = 1, params = {}},
    };
    ["get-admins"] = {
      {n = 0, params = {}},
    };
    ["reload-validator"] = {
      {n = 1, params = {}},
    };
    ["del-validator"] = {
      {n = 1, params = {}},
    };
    ["get-validators"] = {
      {n = 0, params = {}},
    };
    ["set-max-channels"] = {
      {n = 1, params = {}},
    };
    ["get-max-channels"] = {
      {n = 0, params = {}},
    };
    ["set-log-level"] = {
      {n = 1, params = {}},
    };
    ["get-log-level"] = {
      {n = 0, params = {}},
    };
    ["set-oil-log-level"] = {
      {n = 1, params = {}},
    };    
    ["get-oil-log-level"] = {
      {n = 0, params = {}},
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
      elseif params[opt] == null and opt ~= "password"  then
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
    local params, msg, succ, cmdname, cmdval, cmddesc
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
    return true
  end

  ---
  -- Adiciona um novo sistema no barramento.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["add-category"] = function(cmd)
    local conn = connect()
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    if validId(id) then
      local ok, err = pcall(conn.entities.createEntityCategory, conn.entities,
          id, cmd.params.name)
      if not ok then
        if err._repid == authotypes.EntityCategoryAlreadyExists then
          printf("[ERRO] Categoria '%s' já cadastrada", id)
        else
          printf("[ERRO] Erro inesperado ao adicionar categoria: %s", tostring(err))
        end
        return false
      end
    else
      printf("[ERRO] Falha ao adicionar categoria '%s': " ..
             "identificador inválido", id)
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
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local ok, category = pcall(conn.entities.getEntityCategory, conn.entities, id)
    if not ok then 
      printf("[ERRO] Erro inesperado ao remover categoria: %s", tostring(category))
      return false
    end
    if not category then 
      printf("[ERRO] Categoria '%s' não existe.", id)
      return false
    end
    local ok, err = pcall(category.remove, category)
    if not ok then
      if err._repid == authotypes.EntityCategoryInUse then
        printf("[ERRO] Categoria '%s' em uso.", id)
      else
        printf("[ERRO] Erro inesperado ao remover categoria: %s", tostring(err))
      end
      return false
    end
    printf("[INFO] Categoria '%s' removida com sucesso", id)
    return true
  end

  ---
  -- Altera informações da categoria.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["set-category"] = function(cmd)
    local conn = connect()
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local ok, category = pcall(conn.entities.getEntityCategory, conn.entities,cmd.params[cmd.name])
    if not ok then 
      printf("[ERRO] Erro inesperado ao configurar categoria: %s", tostring(category))
      return false
    end
    if not category then 
      printf("[ERRO] Categoria '%s' não existe.", id)
      return false
    end
    local ok, err = pcall(category.setName, category, cmd.params.name)
    if not ok then 
      printf("[ERRO] Erro inesperado ao configurar categoria: %s", tostring(err))
      return false
    end
    printf("[INFO] Categoria '%s' atualizada com sucesso", id)
    return true
  end

  ---
  -- Exibe informações sobre as categorias.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["list-category"] = function(cmd)
    local ok, categories
    local conn = connect()
    if not conn then
      return false
    end
    -- Busca todas
    if cmd.params[cmd.name] == null then
      ok, categories = pcall(conn.entities.getEntityCategories, conn.entities)
      if not ok then 
        printf("[ERRO] Erro inesperado ao listar categorias: %s", tostring(categories))
        return false
      end
    else
      -- Busca uma categoria específica
      local ok, category = pcall(conn.entities.getEntityCategory, conn.entities, cmd.params[cmd.name])
      if not ok then 
        printf("[ERRO] Erro inesperado ao listar categorias: %s", tostring(category))
        return false
      end
      if not category then 
        printf("[ERRO] Categoria '%s' não existe.", tostring(cmd.params[cmd.name]))
        return false
      end
      local ok, description = pcall(category.describe, category)
      if not ok then 
        printf("[ERRO] Erro inesperado ao listar categorias: %s", tostring(description))
        return false
      end
      categories = {description}
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
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    if not validId(id) then
      printf("[ERRO] Falha ao adicionar entidade '%s': " ..
             "identificador inválido", id)
      return false
    end

    local ok, category = pcall(conn.entities.getEntityCategory, conn.entities, cmd.params.category)
    if not ok then 
      printf("[ERRO] Erro inesperado ao recuperar categoria: %s", tostring(category))
      return false
    end
    if not category then 
      printf("[ERRO] Categoria '%s' não existe.", cmd.params.category)
      return false
    end
    local ok, err = pcall(category.registerEntity, category, id, cmd.params.name)
    if not ok then
      if err._repid == authotypes.EntityAlreadyRegistered then
        printf("[ERRO] Entidade '%s' já cadastrada.", id)
      else
        printf("[ERRO] Erro inesperado ao adicionar entidade: %s", tostring(err))
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
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local ok, entity = pcall(conn.entities.getEntity, conn.entities, id)
    if not ok then 
      printf("[ERRO] Erro inesperado ao remover entidade: %s", tostring(entity))
      return false
    end
    if not entity then
      printf("[ERRO] Entidade '%s' inexistente.", id)
      return false
    end
    entity:remove()
    -- se tiver certificado, remove
    local ok, err = pcall(conn.certificates.removeCertificate, conn.certificates, id)
    if not ok then 
      printf("[ERRO] Erro inesperado ao remover entidade: %s", tostring(err))
      return false
    end
    printf("[INFO] Entidade '%s' removida com sucesso", id)
    return true
  end

  ---
  -- Altera informações da entidade.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["set-entity"] = function(cmd)
    local conn = connect()
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local ok, entity = pcall(conn.entities.getEntity, conn.entities, id)
    if not ok then 
      printf("[ERRO] Erro inesperado ao configurar entidade: %s", tostring(entity))
      return false
    end
    if not entity then
      printf("[ERRO] Entidade '%s' não existe.", id)
      return false
    end
    local ok, err = pcall(entity.setName, entity, cmd.params.name)
    if not ok then 
      printf("[ERRO] Erro inesperado ao configurar entidade: %s", tostring(err))
      return false
    end
    printf("[INFO] Entidade '%s' atualizada com sucesso", id)
    return true
  end

  ---
  -- Exibe informações das entidades.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["list-entity"] = function(cmd)
    local entities, ok
    local conn = connect()
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local category = cmd.params.category
    if id == null then
      -- TODO: possivelmente, a verficacao category == null é um bug
      if not category or category == null then
        -- Busca todos
        ok, entities = pcall(conn.entities.getEntities, conn.entities)
        if not ok then 
          printf("[ERRO] Erro inesperado ao listar entidades: %s", tostring(entities))
          return false
        end
      else
        -- Filtra por categoria
        local ok, category = pcall(conn.entities.getEntityCategory, conn.entities, category)
        if not ok then 
          printf("[ERRO] Erro inesperado ao listar entidades: %s", tostring(category))
          return false
        end
        if not category then 
          printf("[ERRO] Categoria '%s' não existe.", cmd.params.category)
          return false
        end
        ok, entities = pcall(category.getEntities, category)
        if not ok then 
          printf("[ERRO] Erro inesperado ao listar entidades: %s", tostring(entities))
          return false
        end
      end
    else
      -- Busca apenas uma implantação
      local ok, entity = pcall(conn.entities.getEntity, conn.entities, id)
      if not ok then 
        printf("[ERRO] Erro inesperado ao listar entidades: %s", tostring(entity))
        return false
      end
      if not entity then
        printf("[ERRO] Entidade '%s' não existe.", id)
        return false
      else 
        local ok, description = pcall(entity.describe, entity)
        if not ok then 
          printf("[ERRO] Erro inesperado ao listar entidades: %s", tostring(description))
          return false
        end
        entities = {description}
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
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    if not validId(id) then
      printf("[ERRO] Falha ao adicionar certificado '%s': " ..
             "identificador inválido", id)
      return false
    end
    
    local certificate = cmd.params.certificate
    local f = io.open(certificate, "rb")
    if not f then
      print("[ERRO] Não foi possível localizar arquivo de certificado")
      return false
    end
    local cert = f:read("*a")
    if not cert then
      print("[ERRO] Não foi possível ler o certificado")
      return false
    end
    local ok, err = pcall(conn.certificates.registerCertificate,
        conn.certificates, id, cert)
    if not ok then
      if err._repid == admintypes.InvalidCertificate then
        printf("[ERRO] Certificado inválido: '%s'", certificate)
      else
        printf("[ERRO] Erro inesperado ao incluir certificado: %s", tostring(ret))
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
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local ok, ret = pcall(conn.certificates.removeCertificate, conn.certificates, id)
    if not ok then 
      printf("[ERRO] Erro inesperado ao remover certificado: %s", tostring(ret))
      return false
    end
    if ret then
      printf("[INFO] Certificado da entidade '%s' removido com sucesso", id)
    else
      printf("[INFO] Certificado da entidade '%s' não existe", id)
    end
    return ret
  end

  ---
  -- Exibe entidades que possuem um certificado cadastrado.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["list-certificate"] = function(cmd)
    local conn = connect()
    if not conn then
      return false
    end
    local ok, identifiers = pcall(conn.certificates.getEntitiesWithCertificate, conn.certificates)
    if not ok then
      printf("[ERRO] Erro inesperado ao listar entidades com certificado: %s", tostring(identifiers))
      return false
    end
    printer.showIdentifier(identifiers)
    return true
  end

  ---
  -- Adiciona um nova interface.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["add-interface"] = function(cmd)
    local conn = connect()
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local ok, err = pcall(conn.interfaces.registerInterface, conn.interfaces, id)
    if not ok then
      if err._repid == authotypes.InvalidInterface then
        printf("[ERRO] Interface '%s' inválida.", id)
      else
        printf("[ERRO] Erro inesperado ao adicionar interface: %s", tostring(err))
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
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local ok, err = pcall(conn.interfaces.removeInterface, conn.interfaces, id)
    if not ok then
      if err._repid == authotypes.InterfaceInUse then
        printf("[ERRO] Interface '%s' em uso.", id)
      else
        printf("[ERRO] Erro inesperado ao remover interface: %s", tostring(err))
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
    if not conn then
      return false
    end
    local ok, interfaces = pcall(conn.interfaces.getInterfaces, conn.interfaces)
    if not ok then
      printf("[ERRO] Erro inesperado ao listar interfaces: %s", tostring(interfaces))
      return false
    end
    printer.showInterface(interfaces)
    return true
  end

  ---
  -- Altera a autorização de um membro do barramento.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["set-authorization"] = function(cmd)
    local conn = connect()
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local ok, entity = pcall(conn.entities.getEntity, conn.entities, id)
    if not ok then
      printf("[ERRO] Erro inesperado ao configurar autorizações: %s", tostring(entity))
      return false
    end
    if not entity then
      printf("[ERRO] Entidade '%s' não existe.", id)
      return false
    end
    local interface
    local err
    if cmd.params.grant then
      -- Concede uma autorização
      interface = cmd.params.grant
      ok, err = pcall(entity.grantInterface, entity, interface)
      if not ok then
        if err._repid == authotypes.InvalidInterface then
          printf("[ERRO] Interface '%s' inválida.", interface)
        else
          printf("[ERRO] Erro inesperado ao configurar autorizações: %s", tostring(err))
        end
        return false
      end
      printf("[INFO] Autorização concedida a '%s': %s", id, interface)
    else
      -- Revoga autorização
      interface = cmd.params.revoke
      ok, err = pcall(entity.revokeInterface, entity, interface)
      if not ok then
        if err._repid == authotypes.InvalidInterface then
          printf("[ERRO] Interface '%s' inválida.", interface)
        elseif err._repid == authotypes.AuthorizationInUse then
          printf("[ERRO] Autorização '%s' em uso pela entidade '%s'.", interface,
            id)
        else
          printf("[ERRO] Erro inesperado ao configurar autorizações: %s", tostring(err))
        end
        return false
      end
      printf("[INFO] Autorização revogada de '%s': %s", id, interface)
    end
    return true
  end

  ---
  -- Exibe as autorizações.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["list-authorization"] = function(cmd)
    local auths = {}
    local conn = connect()
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    if id == null then
      if not cmd.params.interface or cmd.params.interface == null then
        -- Busca todas
        local ok, ents = pcall(conn.entities.getAuthorizedEntities, conn.entities)
        if not ok then
          printf("[ERRO] Erro inesperado ao listar autorizações: %s", tostring(ents))
          return false
        end
        for _, entitydesc in ipairs(ents) do 
          local authorization = {}
          authorization.id = entitydesc.id
          local ok, ifaces = pcall(entitydesc.ref.getGrantedInterfaces, entitydesc.ref)
          if not ok then
            printf("[ERRO] Erro inesperado ao listar autorizações: %s", tostring(ifaces))
            return false
          end
          authorization.interfaces = ifaces
          table.insert(auths, authorization)
        end
      else
        -- Filtra por interfaces
        local ifaces = {}
        for iface in string.gmatch(cmd.params.interface, "%S+") do
          ifaces[#ifaces+1] = iface
        end
        local ok, ents = pcall(conn.entities.getEntitiesByAuthorizedInterfaces, conn.entities, ifaces)
        if not ok then
          printf("[ERRO] Erro inesperado ao listar autorizações: %s", tostring(ents))
          return false
        end
        for _, entitydesc in ipairs(ents) do 
          local authorization = {}
          authorization.id = entitydesc.id
          local ok, ifaces = pcall(entitydesc.ref.getGrantedInterfaces, entitydesc.ref)
          if not ok then
            printf("[ERRO] Erro inesperado ao listar autorizações: %s", tostring(ifaces))
            return false
          end
          authorization.interfaces = ifaces
          table.insert(auths, authorization)
        end
      end
    else
      -- Busca por entidade
      local ok, entity = pcall(conn.entities.getEntity, conn.entities, id)
      if not ok then
        printf("[ERRO] Erro inesperado ao listar autorizações: %s", tostring(entity))
        return false
      end
      if not entity then
        printf("[ERRO] Entidade '%s' não existe.", id)
        return false
      end
      local authorization = {}
      authorization.id = id
      local ok, ifaces = pcall(entity.getGrantedInterfaces, entity)
      if not ok then
        printf("[ERRO] Erro inesperado ao listar autorizações: %s", tostring(ifaces))
        return false
      end
      authorization.interfaces = ifaces
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
    local conn = connect()
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    local ok, bool = pcall(conn.logins.invalidateLogin, conn.logins, id)
    if not ok then
      printf("[ERRO] Erro inesperado ao remover login: %s", tostring(bool))
      return false
    end
    if not bool then
      printf("[ERRO] Login '%s' é inválido.", id)
      return false
    end
    printf("[INFO] Login '%s' removido com sucesso.", id)
    return true
  end

  ---
  -- Exibe os logins.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["list-login"] = function(cmd)
    local ok, logins
    local conn = connect()
    if not conn then
      return false
    end
    if not cmd.params.entity or cmd.params.entity == null then
      -- Busca todos
      ok, logins = pcall(conn.logins.getAllLogins, conn.logins)
      if not ok then
        printf("[ERRO] Erro inesperado ao listar logins: %s", tostring(logins))
        return false
      end
    else
      -- Filtra por entidade
      ok, logins = pcall(conn.logins.getEntityLogins, conn.logins, cmd.params.entity)
      if not ok then
        printf("[ERRO] Erro inesperado ao listar logins: %s", tostring(logins))
        return false
      end
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
    return true
  end

  ---
  -- Exibe as ofertas cadastradas.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["list-offer"] = function(cmd)
    local offers, ok
    local conn = connect()
    if not conn then
      return false
    end
    local id = cmd.params[cmd.name]
    if id == null then 
      -- Lista todos
      ok, offers = pcall(conn.offers.getAllServices, conn.offers)
      if not ok then
        printf("[ERRO] Erro inesperado ao listar ofertas: %s", tostring(offers))
        return false
      end
    else
      -- Filtra por entidade
      ok, offers = pcall(conn.offers.findServices, conn.offers, {{name="openbus.offer.entity",value=id}})
      if not ok then
        printf("[ERRO] Erro inesperado ao listar ofertas: %s", tostring(offers))
        return false
      end
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
    if not conn then
      return false
    end
    local offers, ok
    local id = cmd.params.entity
    if not id or id == null then
      ok, offers = pcall(conn.offers.getAllServices, conn.offers)
      if not ok then
        printf("[ERRO] Erro inesperado ao remover oferta: %s", tostring(offers))
        return false
      end
    else
      ok, offers = pcall(conn.offers.findServices, conn.offers, {{name="openbus.offer.entity",value=id}})
      if not ok then
        printf("[ERRO] Erro inesperado ao remover oferta: %s", tostring(offers))
        return false
      end
    end
    local descs = printer.showOffer(offers)
    if #descs == 0 then
      return true
    end
    print("Informe o índice da oferta que deseja remover:")
    local id = tonumber(io.read())
    if id ~= nil and descs[id] ~= nil then
      for key, value in pairs (descs[id]) do
        if key == "id" and value == id then
          descs[id].offer:remove()
        end
      end
    else
      printf("[ERRO] Índice de oferta inválido: '%d'", id)
      return false
    end
    printf("[INFO] Oferta '%d' removida com sucesso.", id)
    return true
  end

  ---
  -- Lista as propriedades da oferta cadastrada.
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["list-props"] = function(cmd)
    local conn = connect()
    if not conn then
      return false
    end
    local ok, offers
    local id = cmd.params[cmd.name]
    if not id or id == null then
      ok, offers = pcall(conn.offers.getAllServices, conn.offers)
      if not ok then
        printf("[ERRO] Erro inesperado ao listar propriedades: %s", tostring(offers))
        return false
      end
    else
      ok, offers = pcall(conn.offers.findServices, conn.offers, {{name="openbus.offer.entity",value=id}})
      if not ok then
        printf("[ERRO] Erro inesperado ao listar propriedades: %s", tostring(offers))
        return false
      end
    end
    local descs = printer.showOffer(offers)
    if #descs == 0 then
      return true
    end
    print("Informe o índice da oferta que deseja listar as propriedades:")
    local id = tonumber(io.read())
    if id ~= nil and descs[id] ~= nil then
      for key, value in pairs (descs[id]) do
        if key == "id" and value == id then
          printer.showOfferProps(descs[id])
        end
      end
    else
      printf("[ERRO] Índice de oferta inválido: '%d'", id)
      return false
    end
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

  ---
  -- Encerra a execução dos serviços do núcleo do barramento
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["shutdown"] = function(cmd)
    local conn = connect()
    if not conn then
      return false
    end
    local ok, errmsg = pcall(conn.bus.shutdown, conn.bus)
    if not ok then
      printf("[ERRO] Erro inesperado ao encerrar o barramento: %s", tostring(errmsg))
      return false
    end
    return true
  end
  
  local function handleConfigurationCall(cmd, method, paramtype)
    local conn = connect()
    if not conn then
      return false
    end
    local param = cmd.params[cmd.name]
    param = (paramtype and paramtype == "number") and tonumber(param) or param
    local ok, res = pcall(conn.configuration[method],
			  conn.configuration, param)
    if not ok then
      print('[ERRO]: '..res.message)
      return false
    end
    return ok, res
  end

  handlers["reload-configs-file"] = function()
    local conn = connect()
    if not conn then
      return false
    end
    conn.configuration:reloadConfigsFile()
    return true
  end

  local function list2table(list)
    local t = {}
    for entry in string.gmatch(list, "%S+") do
      t[#t+1] = entry
    end
    return t
  end

  local function handleConfigurationGetCall(cmd, method, attr)    
    local ok, res = handleConfigurationCall(cmd, method)
    if ok then
       if type(res) == "table" then
	 local admins = "{ "
	 admins = admins..table.concat(res, ", ")
	 admins = admins.." }"
	 res = admins
       end
      print(attr.." = "..tostring(res))
    end
    return ok
  end
  
  handlers["grant-admin-to"] = function(cmd)
    cmd.params[cmd.name] = list2table(cmd.params[cmd.name])
    return handleConfigurationCall(cmd, "grantAdminTo")
  end

  handlers["revoke-admin-from"] = function(cmd)
    cmd.params[cmd.name] = list2table(cmd.params[cmd.name])
    return handleConfigurationCall(cmd, "revokeAdminFrom")
  end

  handlers["get-admins"] = function(cmd)
    return handleConfigurationGetCall(cmd, "getAdmins", "admins")
  end

  local function handleValidator(cmd, action)
    return handleConfigurationCall(cmd, action.."Validator")
  end

  handlers["reload-validator"] = function(cmd)
    return handleValidator(cmd, "reload")
  end

  handlers["del-validator"] = function(cmd)
    return handleValidator(cmd, "del")
  end

  handlers["get-validators"] = function(cmd)
    return handleConfigurationGetCall(cmd, "getValidators", "validators")
  end

  handlers["set-max-channels"] = function(cmd)
    return handleConfigurationCall(cmd, "setMaxChannels", "number")
  end

  handlers["get-max-channels"] = function(cmd)
    return handleConfigurationGetCall(cmd, "getMaxChannels", "maxchannels")
  end

  handlers["set-log-level"] = function(cmd)
    return handleConfigurationCall(cmd, "setLogLevel", "number")
  end

  handlers["get-log-level"] = function(cmd)
    return handleConfigurationGetCall(cmd, "getLogLevel", "loglevel")
  end

  handlers["set-oil-log-level"] = function(cmd)
    return handleConfigurationCall(cmd, "setOilLogLevel", "number")
  end

  handlers["get-oil-log-level"] = function(cmd)
    return handleConfigurationGetCall(cmd, "getOilLogLevel", "oilloglevel")
  end

  ---
  -- Monta um relatório sobre o estado atual do barramento
  --
  -- @param cmd Comando e seus argumentos.
  --
  handlers["report"] = function(cmd)
    local localPassword = password
    if not localPassword then
      localPassword = lpw.getpass("Senha: ")
    end
    
    printf("RELATÓRIO DE STATUS DO BARRAMENTO (HOST:%s PORT:%d)", host, port)
    local msg
    local orb = neworb()
    -- check bus
    msg = " - Barramento (versão 2.0.x): %s"
    local ref = "corbaloc::"..host..":"..port.."/"..BusObjectKey
    local bus = orb:newproxy(ref, nil, "scs::core::IComponent")
    local ok, status = pcall(bus._non_existent, bus) 
    if ok then
      if status then
        printf(msg, "[INACESSÍVEL]")
        orb:shutdown()
        return false
      else
        printf(msg, "[ACESSÍVEL]")
      end
    else
      local errmsg = string.format("[ERRO] %s", status._repid)
      printf(msg, errmsg)
      orb:shutdown()
      return false
    end
    bus = nil
    ref = nil
    -- check legacy
    msg = " - Suporte legado (versão 1.5.x): %s"
    local legacyref = "corbaloc::"..host..":"..port.."/openbus_v1_05"
    local legacy = orb:newproxy(legacyref, nil, "scs::core::IComponent")
    ok, status = pcall(legacy._non_existent, legacy) 
    if ok then
      if status then
        printf(msg, "[DESABILITADO]")
      else
        printf(msg, "[HABILITADO]")
      end
    else
      local errmsg = string.format("[ERRO] %s", status._repid)
      printf(msg, errmsg)
    end
    orb:shutdown()
    legacyref = nil
    legacy = nil
    orb = nil

    local conn = OpenBusContext:createConnection(host, port)
    OpenBusContext:setDefaultConnection(conn)
    if not doLogin(conn) then
      return false
    end
    -- TODO:[maia] Code is too much repetivie to make the following changes as
    --             they should be done. Using the following workaround do avoid
    --             changing the same code repeated many times in the code.
    conn.logins = OpenBusContext:getLoginRegistry()
    conn.certificates = OpenBusContext:getCertificateRegistry()
    conn.entities = OpenBusContext:getEntityRegistry()
    conn.interfaces = OpenBusContext:getInterfaceRegistry()
    conn.offers = OpenBusContext:getOfferRegistry()
    -- END OF TODO
    connection = conn
    local isadmin = false

    msg = " - Logins ativos: %s"
    local ok, logins = pcall(conn.logins.getAllLogins, conn.logins)
    if not ok then
      if logins._repid == types.UnauthorizedOperation then
        -- "[ERRO] Requer permissão de ADMINISTRADOR"
        -- não mostra nada.
      else
        local errormsg = string.format("[ERRO]\n%s", tostring(logins))
        printf(msg, errormsg)
      end
    else
      -- removendo o próprio login da contagem
      printf(msg, #logins - 1)
      isadmin = true
    end
    
    msg = " - Categorias cadastradas: %s"
    local ok, categories = pcall(conn.entities.getEntityCategories, conn.entities)
    if not ok then 
      local errormsg = string.format("[ERRO]\n%s", tostring(categories))
      printf(msg, errormsg)
    else
      printf(msg, #categories)
    end
    
    msg = " - Entidades cadastradas: %s"
    local ok, entities = pcall(conn.entities.getEntities, conn.entities)
    if not ok then 
      local errormsg = string.format("[ERRO]\n%s", tostring(entities))
      printf(msg, errormsg)
    else
      printf(msg, #entities)
    end
    
    msg = " - Interfaces cadastradas: %s"
    local ok, interfaces = pcall(conn.interfaces.getInterfaces, conn.interfaces)
    if not ok then 
      local errormsg = string.format("[ERRO]\n%s", tostring(interfaces))
      printf(msg, errormsg)
    else
      printf(msg, #interfaces)
    end
    
    msg = " - Autorizações concedidas: %s"
    local ok, ents = pcall(conn.entities.getAuthorizedEntities, conn.entities)
    if not ok then
      local errormsg = string.format("[ERRO]\n%s", tostring(ents))
      printf(msg, errormsg)
    else
      local authorizations = 0
      for _, entitydesc in ipairs(ents) do 
        local ok, ifaces = pcall(entitydesc.ref.getGrantedInterfaces, entitydesc.ref)
        if not ok then
          local errormsg = string.format("[ERRO]\n%s", tostring(ifaces))
          printf(msg, errormsg)
          break
        else
          authorizations = authorizations + #ifaces
        end
      end
      printf(msg, authorizations)
    end
    
    msg = " - Ofertas publicadas: %s"
    local ok, offers = pcall(conn.offers.getAllServices, conn.offers)
    if not ok then 
      local errormsg = string.format("[ERRO]\n%s", tostring(offers))
      printf(msg, errormsg)
    else
      printf(msg, #offers)
    end

    -- ofertas não responsivas
    if #offers > 0 then
      local invalid = {}
      local failed = {}
      for _, offer in ipairs(offers) do
        local ok, nonexists = pcall(offer.service_ref._non_existent, offer.service_ref)
        if ok then
          if nonexists then
            invalid[#invalid+1] = offer
          end
        else
          offer.error = nonexists._repid
          failed[#failed+1] = offer
        end
      end
      if #failed > 0 then
        printf(" - '%d' Falha(s) inesperada(s) na tentativa de contactar oferta(s):", #failed)
        printer.showFailedOffer(failed)
      end
      if #invalid > 0 then
        printf(" - Existe(m) '%d' Oferta(s) que no momento não estão responsivas:", #invalid)
        printer.showOffer(invalid)
      end
      if #invalid > 0 and isadmin then
        print(" > Deseja remover todas as ofertas não responsivas? [s|n]")
        local reply = string.lower(io.read())
        if reply == "s" or reply == "sim" or reply == "y" or reply == "yes" then
          local rem = 0
          for _, offer in ipairs(invalid) do
            local ok, err = pcall(offer.ref.remove, offer.ref)
            if ok then
              rem = rem + 1
            end
          end
          printf(" - Ofertas não responsivas removidas: %d", rem)
        end
      end
    end
    return true
  end

  -------------------------------------------------------------------------------
  -- Seção de conexão com o barramento e os serviços básicos

  function handleError(err)
    local msg = "[ERRO] Falha no Login! %s"
    if err._repid == logintypes.AccessDenied then
      printf(msg, messages.AccessDeniedOnLogin)
    elseif err._repid == logintypes.MissingCertificate then
      printf(msg, messages.MissingCertificate:tag{entity=login})
    else 
      local errormsg = string.format("\n%s", error(err))
      printf(msg, errormsg)
    end
  end

  function doLogin(conn)
    if privatekey ~= null then
      local prvkey = assert(openbus.readKeyFile(privatekey))
      local ok, err = pcall(conn.loginByCertificate, conn, login, prvkey)
      if not ok then
        handleError(err)
        return false
      end
    else  
      local localPassword = password
      if localPassword == null then
        localPassword = lpw.getpass("Senha: ")
      end
      local ok, err = pcall(conn.loginByPassword, conn, login, localPassword)
      if not ok then
        handleError(err)
        return false
      end
    end
    return true
  end
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
    local conn = OpenBusContext:createConnection(host, port)
    OpenBusContext:setDefaultConnection(conn)
    if not doLogin(conn) then
      return nil
    end
    -- TODO:[maia] Code is too much repetivie to make the following changes as
    --             they should be done. Using the following workaround do avoid
    --             changing the same code repeated many times in the code.
    conn.logins = OpenBusContext:getLoginRegistry()
    conn.certificates = OpenBusContext:getCertificateRegistry()
    conn.entities = OpenBusContext:getEntityRegistry()
    conn.interfaces = OpenBusContext:getInterfaceRegistry()
    conn.offers = OpenBusContext:getOfferRegistry()
    local ref = "corbaloc::"..host..":"..port
      .."/"..BusObjectKey.."/Configuration"
    conn.configuration = orb:newproxy(ref, nil,
      "tecgraf::openbus::core::v2_0::services::admin::v1_0::Configuration")
    -- END OF TODO
    connection = conn
    return connection
  end

  -- Faz o parser da linha de comando.
  -- Verifica se houve erro e já despacha o comando de ajuda para evitar
  -- a conexão com os serviços do barramento
  local command, msg = parse{...}
  if not command then
    print("[ERRO] " .. msg)
    print("[HINT] --help")
    orb:shutdown()
    os.exit(1)
  elseif command.name == "help" then
    handlers.help(command)
    orb:shutdown()
    os.exit(0)
  elseif (not command.params.login) or (command.params.login == null) then
    print("[ERRO] Usuário não informado")
    orb:shutdown()
    os.exit(1)
  end

  -- Recupera os valores globais
  login    = command.params.login
  privatekey = command.params.privatekey
  password = command.params.password
  host  = command.params["host"]
  port  = tonumber(command.params["port"])

  -- setup log files
  log:level(tonumber(command.params.verbose))
  oillog:level(tonumber(command.params.oilverbose))
  
  ---
  -- Função principal responsável por despachar o comando.
  --
  local ok, result = pcall(handlers[command.name], command)

  if connection ~= nil then
    connection:logout()
    OpenBusContext:setDefaultConnection(nil)
    connection = nil
  end
  orb:shutdown()

  if not ok then
    print(result)
    os.exit(1)
  elseif result == false then
    os.exit(1)
  else
    os.exit(0)
  end  
end
