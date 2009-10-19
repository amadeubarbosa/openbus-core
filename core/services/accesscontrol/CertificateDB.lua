local oo     = require "loop.base"
local lfs    = require "lfs"
local os     = require "os"
local io     = require "io"
local string = require "string"

local error  = error
local print  = print

--
-- Classe responsável por gerenciar um diretório de certificados.
--
module("core.services.accesscontrol.CertificateDB", oo.class)

---
-- Cria o objeto para controle dos certificados.
--
-- @param crtpath  Caminho para o  diretório onde os  certificados são
-- guardados.
--
function __init(self, crtpath)
   local mode = lfs.attributes(crtpath, "mode")
   if not mode then
      error("Diretório de certificados não encontrado.")
   elseif mode ~= "directory" then
      error("Diretório de certificados é inválido.")
   end
   return oo.rawnew(self, { crtpath = crtpath })
end

---
-- Salva o certificado do serviço em disco.
-- Se o nome já existir, o ceritificado é sobrescrito.
--
-- ** Atenção: esta função mapeia o nome para arquivo em
-- disco. Atualmente, ela não faz nenhuma verificação se o resultado
-- final está fora do repositório.  Garanta que o nome não possui
-- caracteres que podem ser interpretado como parte do path do sistema
-- operacional.
--
--
-- @param name Nome para identificar o certificado.
-- @param certificate certificado a ser salvo
--
-- @return Retorna true se o certificado foi salvo com sucesso.  Em
-- caso de erro retorna false e uma mensagem descrevendo o erro.
--
function save(self, name, certificate)
   local crtfile = string.format("%s/%s.crt", self.crtpath, name)
   local f, msg, succ
   f, msg = io.open(crtfile, "w")
   if not f then
      return false, msg 
   end
   succ, msg = f:write(certificate)
   f:close()
   return (succ ~= nil), msg
end

---
-- Remove o certificado identificado pelo nome informado.
--
-- ** Atenção: esta função mapeia o nome para arquivo em disco.
-- Atualmente, ela não faz nenhuma verificação se o resultado final
-- está fora do repositório.  Garanta que o nome não possui caracteres
-- que podem ser interpretado como parte do path do sistema
-- operacional.
--
--
-- @param name Nome que identifica o ceritificado a ser removido.
--
-- @return Retorna true se o certificado for removido com
--  sucesso. Caso o certificado não exista, é retornado false seguido
--  da mensagem "not found".  Em caso de erro, é retornado false
--  seguido da mensagem de erro.
--
function remove(self, name)
   local crtfile = string.format("%s/%s.crt", self.crtpath, name)
   local mode = lfs.attributes(crtfile, "mode")
   if not mode then
      return false, "not found"
   elseif mode ~= "file" then
      return false, "not a file"
   end
   local succ, msg = os.remove(crtfile)
   return (succ ~= nil), msg
end

---
-- Recupera o certifica dado o identificador.
--
-- ** Atenção: esta função mapeia o nome para arquivo em disco.
-- Atualmente, ela não faz nenhuma verificação se o resultado final
-- está fora do repositório.  Garanta que o nome não possui caracteres
-- que podem ser interpretado como parte do path do sistema
-- operacional.
--
--
-- @param name Nome que identifica o certificado.
--
-- @return Retorna o certificado referente ao nome. Caso o certificado
-- não exista,  é retornado  nil seguido da  mensagem "not  found". Em
-- caso de erro, é retornado nil seguido da mensagem de erro.
--
function get(self, name)
   local crtfile = string.format("%s/%s.crt", self.crtpath, name)
   local mode = lfs.attributes(crtfile, "mode")
   if not mode then
      return nil, "not found"
   elseif mode ~= "file" then
      return nil, "not a file"
   end
   local f, cert, msg
   f, msg = io.open(crtfile)
   if not f then
      return nil, msg
   end
   cert, msg = f:read("*a")
   f:close()
   return cert, msg
end

---
-- Retorna  o  caminho  para   o  arquivo  que  contém  o  certificado
-- identificado pelo nome fornecido.
--
-- ** Atenção: esta função mapeia o nome para arquivo em disco.
-- Atualmente, ela não faz nenhuma verificação se o resultado final
-- está fora do repositório.  Garanta que o nome não possui caracteres
-- que podem ser interpretado como parte do path do sistema
-- operacional.
--
-- @param name Nome que identifica o ceritificado.
--
-- @return Retorna  o caminho para  o certificado. Caso  o certificado
-- não exista,  é retornado  nil seguido da  mensagem "not found". Em
-- caso de erro, é retornado nil seguido da mensagem de erro.
--
function getPath(self, name)
   local crtfile = string.format("%s/%s.crt", self.crtpath, name)
   local mode = lfs.attributes(crtfile, "mode")
   if not mode then
      return nil, "not found"
   elseif mode == "file" then
      return crtfile
   end
   return nil, "not a file"
end
