local lpw     = require "lpw"
local oil     = require "oil"
local Openbus = require "openbus.Openbus"

-- Verifica se as variável de ambiente está definida antes de continuar
local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if not IDLPATH_DIR then
  print("[ERRO] Caminho das IDLs não informado\n")
  os.exit(1)
end

-- Variáveis que são referenciadas antes de sua crição
-- Não usar globais para não exportá-las para o comando 'script'
local login, password
local acshost, acsport
local acsmgm, getacsmgm
local rsmgm, getrsmgm

-- Guarda as funções que serão os tratadores das ações de linha de comando
local handlers = {}

-- Nome do script principal (usado no help)
local program = arg[0]

-- String de help
local help = [[

Uso: %s [opções] --login=<usuário> <comando>

-------------------------------------------------------------------------------
- Opções
  * Informa o endereço do Serviço de Acesso (padrão 127.0.0.1):
    --acs-host=<endereço>
  * Informa a porta do Serviço de Acesso (padrão 2089):
    --acs-port=<porta>

- Controle de Sistema
  * Adicionar sistema:
     --add-system=<id_sistema> --description=<descrição>
  * Remover sistema:
     --del-system=<id_sistema>
  * Alterar descrição:
     --set-system=<id_sistema> --description=<descrição>
  * Mostrar todos os sistemas:
     --list-system
  * Mostrar informações sobre um sistema:
     --list-system=<id_sistema>

- Controle de Implantação
  * Adicionar implantação:
     --add-deployment=<id_implantação> --system=<id_sistema> --description=<descrição> --certificate=<arquivo>
  * Alterar descrição:
     --set-deployment=<id_implantação> --description=<descrição>
  * Alterar certificado:
     --set-deployment=<id_implantação> --certificate=<arquivo>
  * Remover implantação:
     --del-deployment=<id_implantação>
  * Mostrar todas implantações:
     --list-deployment
  * Mostrar informações sobre uma implantação:
     --list-deployment=<id_implantação>
  * Mostrar implantações de um sistema:
     --list-deployment --system=<id_sistema>

- Controle de Interface
  * Adicionar interface:
     --add-interface=<interface>
  * Remover interface:
     --del-interface=<interface>
  * Mostrar todas interfaces:
     --list-interface

- Controle de Autorização
  * Conceder autorização:
     --set-authorization=<id_implantação> --grant=<interface>
  * Revogar autorizaçãoL
     --set-authorization=<id_implantação> --revoke=<interface>
  * Remover autorização:
     --del-authorization=<id_implantação>
  * Mostrar todas as autorizações
     --list-authorization
  * Mostrar uma autorização
     --list-authorization=<id_implantação>
  * Mostrar autorizações de um sistema
     --list-authorization --system=<id_sistema>
  * Mostrar todas autorizações com as interfaces
     --list-authorization --interface="<iface1> <iface2> ... <ifaceN>"

- Script
  * executa script Lua com um lote de comandos
     --script=<arquivo>
-------------------------------------------------------------------------------
]]

-------------------------------------------------------------------------------
-- Define o parser da linha de comando.
--

-- Este valor é usado no parser (e só no parser) da linha de comando:
--  * 'null' quer dizer que o parâmetro foi informado, mas sem valor. 
--  * 'nil' quer dizer ausência do parâmetro.
-- Após o parser, o valor 'null' é convertido em 'nil'.
local null = {}

--
-- Valor padrão das opções. Caso a linha de comando não informe, estes valores
-- serão copiados para a tabela de linha de comando.
--
local options = {
  ["acs-host"] = "127.0.0.1",
  ["acs-port"] = 2089,
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
-- Nota: se for necessário diferenciar entre as formas dentro de um mesmo
-- comando, pode-se adicionar um campo, por exemplo 'key', que identifica
-- unicamente a forma desejada. (diferenciando até globalmente)
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
    {n = 1, params = {}}
  };
  ["list-authorization"] = {
    {n = 0, params = {}},
    {n = 1, params = {system = 1}},
    {n = 1, params = {interface = 1}},
    {n = 1, params = {}},
  };
  ["script"] = {
    {n = 1, params = {}},
  }
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
      -- Os parâmetros existem e possuem valor?
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
    return nil, "Parâmetros inválidos"
  end
  for k, v in pairs(params) do
    if v == null then params[k] = nil end
  end
  return {
    name = cmdname,
    params = params,
  }
end

-------------------------------------------------------------------------------
-- Define as funções que imprimem as informações na tela em forma de relatório.
--

---
-- Imprime uma linha divisória de acordo com o tamanho das colunas.
-- O tamanho total da linha é normalizado para no mínimo 80 caracteres.
--
-- @param sizes Array com o tamanho de cada coluna
--
local function hdiv(sizes)
  local l = {}
  for k, size in ipairs(sizes) do
    l[k] = string.rep("-", size+2)
  end
  l = table.concat(l, "+")
  if #l < 80 then
    l = l .. string.rep("-", 80-#l)
  end
  print(l)
end

---
-- Imprime os títulos das colunas, preenchendo o necessário com espaço para
-- completar o tamanho esperado da coluna.
--
-- @param titles Títulos das colunas.
-- @param sizes Array com os tamanhos das colunas.
--
local function header(titles, sizes)
  local l = {}
  for k, title in ipairs(titles) do
    l[k] = string.format(" %s%s ", title, string.rep(" ", sizes[k]-#title))
  end
  hdiv(sizes)
  print(table.concat(l, "|"))
  hdiv(sizes)
end

---
-- Imprime uma linha de dados.
--
-- @param sizes Array com o tamanho das colunas. Ele também indica quantas
-- colunas devem ser impressas.
-- @param ... Dados a serem impressos em cada coluna.
-- 
local function dataline(sizes, ...)
  local l = {}
  for k, size in ipairs(sizes) do
    local val = select(k, ...)
    l[k] = string.format(" %s%s ", val, string.rep(" ", size-#val))
  end
  print(table.concat(l, "|"))
end

---
-- Imprime uma linha vazia.
--
-- @param sizes Array com o tamanho das colunas. Ele também indica quantas
-- colunas devem ser impressas.
--
local function emptyline(sizes)
  local l = {}
  for k, size in ipairs(sizes) do
    l[k] = string.rep(" ", size+2)
  end
  print(table.concat(l, "|"))
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
handlers["add-system"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  if validId(id) then
    local succ, err = acsmgm.__try:addSystem(id, cmd.params.description)
    if succ then
      printf("[INFO] Sistema '%s' cadastrado com sucesso", id)
    elseif err[1] == "IDL:openbusidl/acs/SystemAlreadyExists:1.0" then
      printf("[ERRO] Sistema '%s' já cadastrado", id)
    else
      printf("[ERRO] Falha ao adicionar sistema '%s': %s", id, err[1])
    end
  else
    printf("[ERRO] Falha ao adicionar sistema '%s': " ..
           "identificador inválido", id)
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
  local succ, err = acsmgm.__try:removeSystem(id)
  if succ then
    printf("[INFO] Sistema '%s' removido com sucesso", id)
  elseif err[1] == "IDL:openbusidl/acs/SystemInUse:1.0" then
    printf("[ERRO] Sistema '%s' em uso", id)
  elseif err[1] == "IDL:openbusidl/acs/SystemNonExistent:1.0" then
    printf("[ERRO] Sistema '%s' não cadastrado", id)
  else
    printf("[ERRO] Falha ao remover sistema '%s': %s", id, err[1])
  end
end

---
-- Exibe informações sobre os sistemas.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-system"] = function(cmd)
  local systems
  local acsmgm = getacsmgm()
  if not cmd.params[cmd.name] then  -- Busca todos
    systems = acsmgm:getSystems()
  else
    -- Busca um sistema específico
    local succ, system = acsmgm.__try:getSystemById(cmd.params[cmd.name])
    if succ then
      systems = {system}
    else
      if system[1] == "IDL:openbusidl/acs/SystemNonExistent:1.0" then
        systems = {}
      else
        printf("[ERRO] Falha ao recuperar informações: %s", system[1])
        return
      end
    end
  end
  -- Mostra os dados em um forumulário
  local titles = {"", "ID SISTEMA", "DESCRIÇÃO"}
  -- Largura inicial das colunas
  local sizes = {3, #titles[2], #titles[3]}
  if #systems == 0 then
    header(titles, sizes)
    emptyline(sizes)
    hdiv(sizes)
  else
    -- Ajusta as larguras das colunas de acordo com o conteúdo
    for k, system in ipairs(systems) do
      if #system.id > sizes[2] then
        sizes[2] = #system.id
      end
      if #system.description > sizes[3] then
        sizes[3] = #system.description
      end
    end
    -- Ordena e monta o formulário
    table.sort(systems, function(a, b) return a.id < b.id end)
    header(titles, sizes)
    for k, system in ipairs(systems) do
      dataline(sizes, string.format("%.3d", k), system.id, system.description)
    end
    hdiv(sizes)
  end
end

---
-- Altera informações do sistema.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-system"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  local succ, err = acsmgm.__try:setSystemDescription(id, 
    cmd.params.description)
  if succ then
    print(string.format("[INFO] Sistema '%s' atualizado com sucesso", id))
  elseif err[1] == "IDL:openbusidl/acs/SystemNonExistent:1.0" then
    print(string.format("[ERRO] Sistema '%s' não cadastrado", id))
  else
    print(string.format("[ERRO] Falha ao atualizar sistema '%s': %s", id, err[1]))
  end
end

---
-- Adiciona uma nova implantação.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-deployment"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  if validId(id) then
    local f = io.open(cmd.params.certificate)
    if not f then
      print("[ERRO] Não foi possível localizar arquivo de certificado")
      return
    end
    local cert = f:read("*a")
    if not cert then
      print("[ERRO] Não foi possível ler o certificado")
      return
    end
    f:close()
    local succ, err = acsmgm.__try:addSystemDeployment(id, cmd.params.system,
      cmd.params.description, cert)
    if succ then
      printf("[INFO] Implantação '%s' cadastrada com sucesso", id)
    elseif err[1] == "IDL:openbusidl/acs/SystemDeploymentAlreadyExists:1.0" then
      printf("[ERRO] Implantação '%s' já cadastrada", id)
    elseif err[1] == "IDL:openbusidl/acs/SystemNonExistent:1.0" then
      printf("[ERRO] Sistema '%s' não cadastrado", cmd.params.system)
    elseif err[1] == "IDL:openbusidl/acs/InvalidCertificate:1.0" then
      printf("[ERRO] Falha ao adicionar implantação '%s': certificado inválido", id)
    else
      printf("[ERRO] Falha ao adicionar implantação '%s': %s", id, err[1])
    end
  else
    printf("[ERRO] Falha ao adicionar implantação '%s': " ..
           "identificador inválido", id)
  end
end

---
-- Remove uma implantação.
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-deployment"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  local succ, err = acsmgm.__try:removeSystemDeployment(id)
  if succ then
    printf("[INFO] Implantação '%s' removida com sucesso", id)
  elseif err[1] ==  "IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0" then
    printf("[ERRO] Implantação '%s' não cadastrada", id)
  else
    printf("[ERRO] Falha ao remover implantação '%s': %s", id, err[1])
  end
end

---
-- Altera informações da implantação.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-deployment"] = function(cmd)
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  if cmd.params.certificate then
    local f = io.open(cmd.params.certificate)
    if not f then
      print("[ERRO] Não foi possível localizar arquivo de certificado")
      return
    end
    local cert = f:read("*a")
    if not cert then
      print("[ERRO] Não foi possível ler o certificado")
      return
    end
    f:close()
    local succ, err = acsmgm.__try:setSystemDeploymentCertificate(id, cert)
    if succ then
      printf("[INFO] Certificado da implantação '%s' atualizado com sucesso", id)
    elseif err[1] ==  "IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0" then
      printf("[ERRO] Implantação '%s' não cadastrada", id)
    elseif err[1] == "IDL:openbusidl/acs/InvalidCertificate:1.0" then
      printf("[ERRO] Falha ao adicionar implantação '%s': certificado inválido", id)
    else
      printf("[ERRO] Falha ao atualizar certificado da implantação '%s': %s", id, err[1])
    end
  end
  if cmd.params.description then
    local succ, err = acsmgm.__try:setSystemDeploymentDescription(id, 
      cmd.params.description)
    if succ then
      printf("[INFO] Descrição da imlantação '%s' atualizada com sucesso", id)
    elseif err[1] == "IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0" then
      printf("[ERRO] Implantação '%s' não cadastrada", id)
    else
      printf("[ERRO] Falha ao atualizar descrição da implantação '%s': %s", id, err[1])
    end
  end
end

---
-- Exibe informações das implantações.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-deployment"] = function(cmd)
  local depls
  local acsmgm = getacsmgm()
  local id = cmd.params[cmd.name]
  local system = cmd.params.system
  -- Busca apenas uma implantação
  if id then
    local succ, depl = acsmgm.__try:getSystemDeployment(id)
    if succ then
      depls = { depl }
    elseif depl[1] == "IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0" then
      depls = {}
    else
      printf("[ERRO] Falha ao recuperar informações: %s", depl[1])
      return
    end
  elseif system then
    -- Filtra por sistema
    depls = acsmgm:getSystemDeploymentsBySystemId(system)
  else
    -- Busca todos
    depls = acsmgm:getSystemDeployments()
  end
  -- Títulos e larguras iniciais das colunas
  local titles = { "", "ID IMPLANTAÇÃO", "ID SISTEMA", "DESCRIÇÃO" }
  local sizes = { 3, #titles[2], #titles[3], #titles[4] }
  if #depls == 0 then
    header(titles, sizes)
    emptyline(sizes)
    hdiv(sizes)
  else
    -- Ajusta as larguras das colunas de acordo com o conteúdo
    for k, depl in ipairs(depls) do
      if sizes[2] < #depl.id then
        sizes[2] = #depl.id
      end
      if sizes[3] < #depl.systemId then
        sizes[3] = #depl.systemId
      end
      if sizes[4] < #depl.description then
        sizes[4] = #depl.description
      end
    end
    -- Ordena e monta o formulário
    table.sort(depls, function(a, b) return a.id < b.id end)
    header(titles, sizes)
    for k, depl in ipairs(depls) do
      dataline(sizes, string.format("%.3d", k), depl.id, depl.systemId,
        depl.description)
    end
    hdiv(sizes)
  end
end

---
-- Adiciona um nova interface.
--
-- @param cmd Comando e seus argumentos.
--
handlers["add-interface"] = function(cmd)
  local rsmgm = getrsmgm()
  local iface = cmd.params[cmd.name]
  local succ, err = rsmgm.__try:addInterfaceIdentifier(iface)
  if succ then
    printf("[INFO] Interface '%s' cadastrada com sucesso", iface)
  elseif err[1] == "IDL:openbusidl/rs/InterfaceIdentifierAlreadyExists:1.0" then
    printf("[ERRO] Interface '%s' já cadastrada", iface)
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
  local succ, err = rsmgm.__try:removeInterfaceIdentifier(iface)
  if succ then
    printf("[INFO] Interface '%s' removida com sucesso", iface)
  elseif err[1] == "IDL:openbusidl/rs/InterfaceIdentifierInUse:1.0" then
    printf("[ERRO] Interface '%s' em uso", iface)
  elseif err[1] == "IDL:openbusidl/rs/InterfaceIdentifierNonExistent:1.0" then
    printf("[ERRO] Interface '%s' não cadastrada", iface)
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
  local ifaces = rsmgm:getInterfaceIdentifiers()
  -- Títulos e larguras iniciais das colunas
  local titles = { "", "INTERFACE" }
  local sizes = { 3, #titles[2] }
  if #ifaces == 0 then
    header(titles, sizes)
    emptyline(sizes)
    hdiv(sizes)
  else
    -- Ajusta as larguras das colunas de acordo com o conteúdo
    for k, iface in ipairs(ifaces) do
      if sizes[2] < #iface then
        sizes[2] = #iface
      end
    end
    -- Ordena e exibe e monta o formulário
    table.sort(ifaces, function(a, b) return a < b end)
    header(titles, sizes)
    for k, iface in ipairs(ifaces) do
      dataline(sizes, string.format("%.3d", k), iface)
    end
    hdiv(sizes)
  end
end

---
-- Altera a autorização de um membro do barramento.
--
-- @param cmd Comando e seus argumentos.
--
handlers["set-authorization"] = function(cmd)
  local succ, err, msg, iface
  local rsmgm = getrsmgm()
  local depl = cmd.params[cmd.name]
  -- Concede uma autorização
  if cmd.params.grant then
    iface = cmd.params.grant
    succ, err = rsmgm.__try:grant(depl, iface)
    msg = string.format("[INFO] Autorização concedida à '%s': %s", depl, iface)
  else
    -- Revoga autorização
    iface = cmd.params.revoke
    succ, err = rsmgm.__try:revoke(depl, iface)
    msg = string.format("[INFO] Autorização revogada de '%s': %s", depl, iface)
  end
  if succ then
    print(msg)
  elseif err[1] == "IDL:openbusidl/rs/SystemDeploymentNonExistent:1.0" then
    printf("[ERRO] Implantação '%s' não cadastrada", depl)
  elseif err[1] == "IDL:openbusidl/rs/InterfaceIdentifierNonExistent:1.0" then
    printf("[ERRO] Interface '%s' não cadastrada", iface)
  elseif err[1] == "IDL:openbusidl/rs/AuthorizationNonExistent:1.0" then
    printf("[ERRO] Implantação '%s' não possui autorização", depl)
  else
    printf("[ERRO] Falha ao alterar autorização: %s", err[1])
  end
end

---
-- Remove todas as autorizações de uma implantação
--
-- @param cmd Comando e seus argumentos.
--
handlers["del-authorization"] = function(cmd)
  local rsmgm = getrsmgm()
  rsmgm:removeAuthorization(cmd.params[cmd.name])
  printf("[INFO] Autorização de '%s' removida com sucesso", 
    cmd.params[cmd.name])
end

---
-- Exibe as autorizações.
--
-- @param cmd Comando e seus argumentos.
--
handlers["list-authorization"] = function(cmd)
  local auths
  local rsmgm = getrsmgm()
  local depl = cmd.params[cmd.name]
  if depl then
    -- Busca de uma única implantação
    local succ, auth = rsmgm.__try:getAuthorization(depl)
    if succ then
      auths = { auth }
    elseif auth[1] == "IDL:openbusidl/rs/AuthorizationNonExistent:1.0" then
      printf("[ERRO] Implantação '%s' não possui autorização", depl)
      return
    else
      printf("[ERRO] Falha ao recuperar informações: %s", auth[1])
      return
    end
  elseif cmd.params.system then
    -- Filtra por sistema
    auths = rsmgm:getAuthorizationsBySystemId(cmd.params.system)
  elseif cmd.params.interface then
    -- Filtra por interface
    local ifaces = {}
    for iface in string.gmatch(cmd.params.interface, "%S+") do
      ifaces[#ifaces+1] = iface
    end
    auths = rsmgm:getAuthorizationsByInterfaceId(ifaces)
  else
    -- Busca todas
    auths = rsmgm:getAuthorizations()
  end
  -- Títulos e larguras das colunas do formulário de resposta
  local titles = { "", "ID IMPLANTAÇÃO", "ID SISTEMA", "INTERFACES"}
  local sizes = { 3, #titles[2], #titles[3], #titles[4] }
  if #auths == 0 then
    header(titles, sizes)
    emptyline(sizes)
    hdiv(sizes)
  else
    -- Ajusta as larguras das colunas de acordo com o conteúdo
    for k, auth in ipairs(auths) do
      if sizes[2] < #auth.deploymentId then
        sizes[2] = #auth.deploymentId
      end
      if sizes[3] < #auth.systemId then
        sizes[3] = #auth.systemId
      end
      for _, iface in ipairs(auth.authorized) do
        if sizes[4] < #iface then
          sizes[4] = #iface
        end
      end
    end
    -- Ordena e monta o formulário
    table.sort(auths, function(a, b)
      return a.deploymentId < b.deploymentId 
    end)
    header(titles, sizes)
    for k, auth in ipairs(auths) do
      if #auth.authorized == 0 then
        dataline(sizes, string.format("%.3d", k), auth.deploymentId, 
          auth.systemId, "")
      else
        -- Uma implantação pode ter várias interfaces
        table.sort(auth.authorized, function(a, b) return a < b end)
        dataline(sizes, string.format("%.3d", k), auth.deploymentId,
          auth.systemId, auth.authorized[1])
        local count = 2
        local total = #auth.authorized
        while count <= total do
          dataline(sizes, "", "", "", auth.authorized[count])
          count = count + 1
        end
      end
    end
    hdiv(sizes)
  end
end

---
-- Carrega e executa um script Lua para lote de comandos
--
-- @param cmd Comando e seus argumentos.
--
handlers["script"] = function(cmd)
  local f, err, str, func, succ
  f, err = io.open(cmd.params[cmd.name])
  if not f then
    printf("[ERRO] Falha ao abrir arquivo: %s", err)
    return
  end
  str, err = f:read("*a")
  f:close()
  if not str then
    printf("[ERRO] Falha ao ler conteúdo do arquivo: %s", err)
    return
  end
  func, err = loadstring(str)
  if not func then
    printf("[ERRO] Falha ao carregar script: %s", err)
    return
  end
  succ, err = oil.pcall(func)
  if not succ then
    printf("[ERRO] Falha ao executar o script: %s", tostring(err))
  end
end

-------------------------------------------------------------------------------
-- Funções exportadas para o script Lua carregado pelo comando 'script'

---
-- Aborta a execução do script reportando um erro nos argumentos.
--
local function argerror()
  printf("[ERRO] Parâmetro inválido (linha %d)",
    debug.getinfo(3, 'l').currentline)
  error()
end

---
-- Cadastra um sistema
-- 
-- @param system Tabela com os campos 'id' e 'description'
--
function System(system)
  if not (type(system) == "table" and type(system.id) == "string" and
     type(system.description) == "string")
  then
    argerror()
  end
  local cmd = {}
  cmd.name = "add-system"
  cmd.params = {}
  cmd.params[cmd.name] = system.id
  cmd.params.description = system.description
  handlers[cmd.name](cmd)
end

---
-- Cadastra uma implantação.
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
-- Cadastra uma interface.
--
-- @param iface Tabela com um campo 'id' contendo o repID da interface.
--
function Interface(iface)
  if not (type(iface) == "table" and type(iface.id) == "string") then
    argerror()
  end
  local cmd = {}
  cmd.name = "add-interface"
  cmd.params = {}
  cmd.params[cmd.name] = iface.id
  handlers[cmd.name](cmd)
end

---
-- Concede a autorização para um conjunto de interfaces.
--
-- @param auth Tabela com o os campos 'id', identificador da implantação,
-- e 'interfaces', array de repID de interfaces para autorizar.
--
function Grant(auth)
  if not (type(auth) == "table" and type(auth.id) == "string" and 
     type(auth.interfaces) == "table")
  then
    argerror()
  end
  local cmd = {}
  cmd.name = "set-authorization"
  cmd.params = {}
  cmd.params[cmd.name] = auth.id
  for n, iface in ipairs(auth.interfaces) do
    cmd.params.grant = iface
    handlers[cmd.name](cmd)
  end
end

---
-- Revoga autorização de um conjunto de interfaces.
--
-- @param auth Tabela com os campos 'id', identificador da implantação,
-- e 'interfaces', array de repID de interfaces para revogar.
--
function Revoke(auth)
  if not (type(auth) == "table" and type(auth.id) == "string" and 
     type(auth.interfaces) == "table")
  then
    argerror()
  end
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
-- Seção de conexão com o barramento e os serviços básicos

---
-- Efetua a conexão com o barramento.
--
local function connect()
  if not Openbus:isConnected() then
    if not password then
      password = lpw.getpass("Senha: ")
    end
    Openbus:resetAndInitialize(acshost, acsport)
    local orb = Openbus:getORB()
    orb:loadidlfile(IDLPATH_DIR .. "/registry_service.idl")
    orb:loadidlfile(IDLPATH_DIR .. "/access_control_service.idl")
    if Openbus:connect(login, password) == false then
      print("[ERRO] Falha no login")
      os.exit(1)
    end
  end
end

---
-- Recupera referência à faceta de gerenciamento do Serviço de Acesso.
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
  local ic = acs:_component()
  ic = orb:narrow(ic, "IDL:scs/core/IComponent:1.0")
  acsmgm = ic:getFacetByName("IManagement")
  acsmgm = orb:narrow(acsmgm, "IDL:openbusidl/acs/IManagement:1.0")
  return acsmgm
end

---
-- Recupera referência à faceta de gerenciamento do Serviço de Registro.
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
  ic = rs:_component()
  ic = orb:narrow(ic, "IDL:scs/core/IComponent:1.0")
  rsmgm = ic:getFacetByName("IManagement")
  rsmgm = orb:narrow(rsmgm, "IDL:openbusidl/rs/IManagement:1.0")
  return rsmgm
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
acshost  = command.params["acs-host"]
acsport  = tonumber(command.params["acs-port"])

oil.verbose:level(tonumber(command.params.verbose))

---
-- Função principal responsável por despachar o comando.
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
