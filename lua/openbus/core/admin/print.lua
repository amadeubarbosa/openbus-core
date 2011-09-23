local oo = require "loop.simple"

local pairs = pairs
local ipairs = ipairs
local select = select
local table = table
local string = string
local print = print
local table = table
local tostring = tostring
local type = type
local lower = string.lower

-------------------------------------------------------------------------------
-- Constantes
--

---
-- O tamanho mínimo da linha da tabela.
---
local MIN_WIDTH = 80

-------------------------------------------------------------------------------
-- Funções auxiliares
--

---
-- Fornece o tamanho do cabeçalho.
--
-- @param titles Título das colunas.
---
local function getHeaderSize(titles)
  local headerSize = {}
  for _,title in ipairs(titles) do
    table.insert(headerSize,#title)
  end
  return headerSize
end

---
-- Ajusta o tamanho das colunas utilizando como base o tamanho do maior
-- elemento contido nas linhas e no cabeçalho.
--
-- @param titles Título das colunas.
-- @param lineList Lista das linhas.
---
local function adjustColumnWidth(titles, lineList)
  local sizes = getHeaderSize(titles)
  for lineNumber, line in ipairs(lineList) do
    for columnIndex,elementList in ipairs(line) do
      for _, element in ipairs(elementList) do
        if #element > sizes[columnIndex] then
          sizes[columnIndex] = #element
        end
      end
    end
  end
  return sizes
end

---
-- Imprime uma linha de dados.
--
-- @param row Os dados a serem impressos em cada coluna.
-- @param sizes Lista com os tamanhos das colunas.
--
local function printRow(row, sizes)
  local columnLength = 0
  for  _, field in ipairs(row) do
    if columnLength < #field then
      columnLength = #field
    end
  end

  local lines = {}
  for i = 1,columnLength do
    lines[i] = {}
    for j, element in ipairs(row) do
      local value = element[i] or ""
      local whiteSpacePadding = string.rep(" ", (sizes[j] - #value))
      lines[i][j] = string.format(" %s%s ", tostring(value), whiteSpacePadding)
    end
    print(table.concat(lines[i], "|"))
  end
end


---
-- Imprime uma linha divisória de acordo com o tamanho das colunas.
-- O tamanho total da linha é normalizado para no mínimo definido na constante
-- MIN_WIDTH.
--
-- @param sizes Lista com os tamanhos das colunas.
--
local function printDivision(sizes)
  local line = {}
  for i, size in ipairs(sizes) do
    line[i] = string.rep("-", (size + 2) )
  end
  line = table.concat(line, "+")
  if #line < MIN_WIDTH then
    line = line .. string.rep("-", (MIN_WIDTH - #line) )
  end
  print(line)
end

---
-- Imprime o cabeçalho preenchendo o necessário com espaço para
-- completar o tamanho esperado.
--
-- @param titles Títulos das colunas.
-- @param sizes Lista com os tamanhos das colunas.
---
local function printHeader(titles, sizes)
  local line = {}
  for i, title in ipairs(titles) do
    line[i] = string.format(" %s%s ", title, string.rep(" ", (sizes[i] - #title) ))
  end

  printDivision(sizes)
  print(table.concat(line, "|"))
  printDivision(sizes)
end

---
-- Imprime a tabela com os dados solicitados.
--
-- @param titles Título das colunas.
-- @param dataList Lista dos elementos que serão exibidos na tabela.
-- @param sizes Lista com os tamanhos das colunas.
---
local function printTable(titles, dataList, sizes)
  printHeader(titles, sizes)
  for i, element in ipairs(dataList) do
    printRow(element, sizes)
  end
  printDivision(sizes)
end

---
-- Imprime uma linha vazia.
--
-- @param sizes Lista com os tamanhos das colunas.
--
local function printEmptyLine(sizes)
  local line = {}
  for i, size in ipairs(sizes) do
    line[i] = string.rep(" ", (size + 2) )
  end
  print(table.concat(line, "|"))
end

---
-- Exibe uma tabela vazia.
--
-- @param titles Título das colunas.
---
local function showEmptyTable(titles)
  local sizes = adjustColumnWidth(titles, {})
  printHeader(titles, sizes)
  printEmptyLine(sizes)
  printDivision(sizes)
end

-------------------------------------------------------------------------------
-- Funções principais
--

local module = {}

---
-- Exibe a tabela com os Sistemas cadastrados no barramento.
--
-- @param system Estrutura definida na IDL.
---
function module.showCategory(categories)
  local titles = {"", "ID CATEGORIA", "NOME"}
  if #categories == 0 then
    showEmptyTable(titles)
    return
  end

  table.sort(categories, function(a, b)
    return lower(a.id) < lower(b.id)
  end)

  local categoryList = {}
  for i, category in ipairs(categories) do
    table.insert(categoryList, { {string.format("%.3d", i)}, {category.id},
        {category.name} })
  end
  local sizes = adjustColumnWidth(titles, categoryList)

  printTable(titles, categoryList, sizes)
end

---
-- Exibe a tabela com as Entidades cadastrados no barramento.
--
-- @param entities Estrutura definida na IDL.
---
function module.showEntity(entities)
  local titles = { "", "ID ENTIDADE", "ID CATEGORIA", "NOME" }
  if #entities == 0 then
    showEmptyTable(titles)
    return
  end

  table.sort(entities, function(a, b)
    return lower(a.id) < lower(b.id)
  end)

  local entityList = {}
  for i, entity in ipairs(entities) do
    table.insert(entityList, { {string.format("%.3d", i)}, {entity.id},
        {entity.category:_get_id()}, {entity.name} })
  end
  local sizes = adjustColumnWidth(titles, entityList)

  printTable(titles, entityList, sizes)
end

---
-- Exibe a tabela com as Interfaces cadastradas no barramento.
--
-- @param interfaces Identificador definido na IDL.
---
function module.showInterface(interfaces)
  local titles = { "", "INTERFACE" }
  if #interfaces == 0 then
    showEmptyTable(titles)
    return
  end

  table.sort(interfaces, function(a, b)
    return lower(a) < lower(b)
  end)

  local interfaceList = {}
  for i, interface in ipairs(interfaces) do
    table.insert(interfaceList, { {string.format("%.3d", i)}, {interface} })
  end
  local sizes = adjustColumnWidth(titles, interfaceList)

  printTable(titles, interfaceList, sizes)
end

---
-- Exibe a tabela com as interfaces oferecidas no barramento.
--
-- @param offers Estrutura definida na IDL.
---
function module.showOffer(offers)
  local titles = { "", "ID OFERTA", "ID MEMBRO", "INTERFACES"}
  if #offers == 0 then
    showEmptyTable(titles)
    return
  end

  table.sort(offers, function(a, b)
    return lower(a.member) < lower(b.member)
  end)

  local offerList = {}
  for i, offer in ipairs(offers) do
    table.sort(offer.interfaces, function(a, b)
      return lower(a) < lower(b)
    end)

    table.insert(offerList, { {string.format("%.3d", i)}, {offer.id},
        {offer.member}, offer.interfaces })
  end
  local sizes = adjustColumnWidth(titles, offerList)

  printTable(titles, offerList, sizes)
end

---
-- Exibe a tabela com as autorizações concedidas no barramento.
--
-- @param authorizations Estrutura que possui os campos 'id' (identificador da
--        entidade) e 'interfaces' (lista das interfaces autorizadas).
---
function module.showAuthorization(authorizations)
  local titles = { "", "ID ENTIDADE", "INTERFACES"}
  if #authorizations == 0 then
    showEmptyTable(titles)
    return
  end

  table.sort(authorizations, function(a, b)
    return lower(a.id) < lower(b.id)
  end)

  local authorizationList = {}
  for i, authorization in ipairs(authorizations) do
    table.sort(authorization.interfaces, function(a, b)
      return lower(a) < lower(b)
    end)
   table.insert(authorizationList, { {string.format("%.3d", i)},
        {authorization.id}, authorization.interfaces })
  end

  local sizes = adjustColumnWidth(titles, authorizationList)
  printTable(titles, authorizationList, sizes)
end

---
-- Exibe a tabela com os logins.
--
-- @param logins Estrutura definida na IDL.
---
function module.showLogin(logins)
  local titles = { "", "ID LOGIN", "ID ENTIDADE"}
  table.sort(logins, function(a, b)
    return lower(a.entity) < lower(b.entity)
  end)
  local loginList = {}
  for i, login in ipairs(logins) do
    table.insert(loginList, { {string.format("%.3d", i)}, {login.id},
         {login.entity} })
  end
  local sizes = adjustColumnWidth(titles, loginList)
  printTable(titles, loginList, sizes)
end

return module
