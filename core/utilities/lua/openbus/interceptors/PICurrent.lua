-- $Id$

local oil = require "oil"
local oop = require "loop.base"

local log = require "openbus.util.Log"

local setmetatable = setmetatable
local tostring = tostring

---
--Objeto que permite a transfer�ncia de informa��es de um interceptador
--para o tratador de uma requisi��o de servi�o.
---
module("openbus.interceptors.PICurrent", oop.class)

---
--Constr�i o objeto.
--
--@return O objeto.
---
function __init(self)

  -- Os valores transferidos ser�o armazenados em uma tabela de chaves fracas.
  -- As chaves dessa tabela s�o as corotinas associadas �s requisi��es.
  -- Assumimos que o oil cria uma nova corotina para cada requisi��o

  local picurrentTable = {}
  setmetatable(picurrentTable, {__mode = "k"})
  return oop.rawnew(self, {picurrentTable = picurrentTable})
end

---
--Insere um valor na tabela de transfer�ncia
--
--@param value O valor.
---
function setValue(self, credential)
  log:interceptor("Definindo o valor {"..credential.identifier..", "..
      credential.owner.."} na "..tostring(oil.tasks.current))
  self.picurrentTable[oil.tasks.current] = credential
end

---
--Obt�m um valor da tabela de transfer�ncia
--
--@return O valor.
---
function getValue(self)
  local credential = self.picurrentTable[oil.tasks.current]
  log:interceptor("Obtendo o valor {"..credential.identifier..", "..
      credential.owner.."} da "..tostring(oil.tasks.current))
  return credential
end
