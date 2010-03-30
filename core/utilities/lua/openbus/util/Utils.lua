-- $Id: $

local type     = type
local print    = print
local pairs    = pairs
local ipairs   = ipairs
local tostring = tostring
local assert   = assert
local unpack   = unpack
local error    = error

local os     = os
local string = string
local table  = table

local oil = require "oil"
local oop = require "loop.base"
local log = require "openbus.util.Log"
local OilUtilities = require "openbus.util.OilUtilities"


---
-- API utilit�ria.
---
module "openbus.util.Utils"

---
--  A interface IAccessControlService.
---
ACCESS_CONTROL_SERVICE_INTERFACE =
  "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0"

---
--  A interface ILeaseProvider.
---
LEASE_PROVIDER_INTERFACE = "IDL:tecgraf/openbus/core/v1_05/access_control_service/ILeaseProvider:1.0"

---
--  A interface IFaultTolerantService.
---
FAULT_TOLERANT_SERVICE_INTERFACE = 
  "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0"
  
---
--  A interface IComponent.
---
COMPONENT_INTERFACE = 
  "IDL:scs/core/IComponent:1.0"
  
---
--  A interface IRegistryService.
---
REGISTRY_SERVICE_INTERFACE =
  "IDL:tecgraf/openbus/core/v1_05/registry_service/IRegistryService:1.0"

  ---
  --  A chave para obten��o do barramento.
  ---
OPENBUS_KEY = "openbus_v1_05"

---
--  As chaves CORBALOC para obten��o das interfaces do ACS.
---
ACCESS_CONTROL_SERVICE_KEY = "ACS_v1_05"
LEASE_PROVIDER_KEY = "LP_v1_05"
FAULT_TOLERANT_ACS_KEY = "FTACS_v1_05"

---
--  As chaves CORBALOC para obten��o das interfaces do RS.
---
REGISTRY_SERVICE_KEY = "RS_v1_05"
FAULT_TOLERANT_RS_KEY = "FTRS_v1_05"

---
--  A interface ISessionService.
---
SESSION_SERVICE_INTERFACE = "IDL:tecgraf/openbus/session_service/v1_05/ISessionService:1.0"

---
--  O nome da faceta do Servi�o de Sess�o.
---
SESSION_SERVICE_FACET_NAME = "ISessionService"

---
--  A interface IHDataService.
---
DATA_SERVICE_INTERFACE = "IDL:openbusidl/data_service/IHDataService:1.0"

---
--  Nome da propriedade que indica o identificador de um componente.
---
COMPONENT_ID_PROPERTY_NAME = "component_id"

---
-- Obt�m refer�ncias para as principais facetas do Servi�o de Controle de
-- Acesso.
--
-- @param orb O ORB a ser utilizado para obter as facetas.
-- @param host String com o host do Servi�o de Controle de Acesso
-- @param port N�mero ou string com a porta do Servi�o de Controle de Acesso
--
-- @return A faceta IAccessControlService, ou nil, caso n�o seja encontrada.
-- @return A faceta ILeaseProvider, ou nil, caso n�o seja encontrada.
-- @return A faceta IComponent, ou nil, caso n�o seja encontrada.
--
function fetchAccessControlService(orb, host, port)
  port = tostring(port)
  local acs = orb:newproxy("corbaloc::".. host .. ":" .. port .. "/" ..
    ACCESS_CONTROL_SERVICE_KEY, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
  if not OilUtilities:existent(acs) then
    log:error("Utils: Faceta IAccessControlService n�o encontrada.")
    error()
  end
  local lp = orb:newproxy("corbaloc::".. host .. ":" .. port .. "/" ..
    LEASE_PROVIDER_KEY, "IDL:tecgraf/openbus/core/v1_05/access_control_service/ILeaseProvider:1.0")
  if not OilUtilities:existent(lp) then
    log:error("Utils: Faceta ILeaseProvider n�o encontrada.")
    error()
  end
  local ic = orb:newproxy("corbaloc::".. host .. ":" .. port .. "/" ..
      OPENBUS_KEY, "IDL:scs/core/IComponent:1.0")
  if not OilUtilities:existent(ic) then
    log:error("Utils: Faceta IComponent n�o encontrada.")
    error()
  end
  local ft = orb:newproxy("corbaloc::".. host .. ":" .. port .. "/" ..  FAULT_TOLERANT_ACS_KEY,
    "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0")
  if not OilUtilities:existent(ft) then
    log:error("Utils: Faceta IFaultTolerantService n�o encontrada.")
    error()
  end
  return acs, lp, ic, ft
end

---
-- Obt�m uma r�plica ativa da lista de r�plicas que s�o recept�culos
-- de dado um componente.  As r�plicas s�o IComponent por�m deseja-se
-- obter uma outra faceta deste componente (ex. IRegistryService)
-- ** O ideal seria que esse m�todo estivesse dentro de AdaptiveReceptacle,
-- ou ainda em um receptacleutils dentro do SCS.
-- Por�m, como teria que estender a interface IReceptacle ou modificar o SCS,
--  e isso entrar� na evolu��o do SCS at� mesmo com a pr�pria 
--  AdaptiveReceptacle, optou-se por colocar esse m�todo aqui na Utils.
--
-- @param orb O ORB a ser utilizado para obter a replica.
-- @param component O componente que cont�m as r�plicas como recept�culos
-- @param receptacleName O nome do recept�culo
-- @param replicaIface A interface da faceta da r�plica
-- @param replicaIDL A IDL da interface da faceta da r�plica
--
-- @return A faceta replicaIface, ou nil, caso n�o seja encontrada.
--
function getReplicaFacetByReceptacle(orb, component, receptacleName, 
                                     replicaIface, replicaIDL)
  local replicaIRecep =  component:getFacetByName("IReceptacles")
  replicaIRecep = orb:narrow(replicaIRecep, "IDL:scs/core/IReceptacles:1.0")
  if replicaIRecep then
    local status, conns = oil.pcall(replicaIRecep.getConnections, 
                                    replicaIRecep,
                                    receptacleName)
    if not status then
      log:error("Nao foi possivel obter o Servi�o [".. replicaIface .. "]: " .. conns[1])
      return nil
    elseif conns[1] then 
      local recepIC = conns[1].objref
      recepIC = orb:narrow(recepIC, "IDL:scs/core/IComponent:1.0")
      local ok, recepFacet =  oil.pcall(recepIC.getFacetByName, recepIC, replicaIface)
      if ok then
          recepFacet = orb:narrow(recepFacet, replicaIDL)
          return recepFacet
      end
      log:error("Nao foi possivel obter a faceta [".. replicaIface .. "]: " .. recepFacet)
    end
  end
  log:error("Nao foi possivel obter o Servi�o [".. replicaIface .. "].")
  return nil
end


function fetchService(orb, objReference, objType)
   
   log:faulttolerance("[fetchService]"..objReference.."-TYPE:"..objType)
   local success, service = oil.pcall(orb.newproxy, orb, objReference, objType)

   if success then 
     --TODO: Quando o bug do oil for consertado, mudar para: if not service:_non_existent() then
     --local succ, non_existent = service.__try:_non_existent()
     --if succ and not non_existent then
    if OilUtilities:existent(service) then
         --OK
           log:faulttolerance("[fetchService] Servico encontrado.")
         --TODO: Essa linha � devido a um outro bug no OiL: type_id = ""
         service.__reference.type_id = objType
         -- fim do TODO
         
         return true, service
     end
    end
    
    log:error("[fetchService]: Servico ".. objReference .." nao encontrado.")
    return false, nil

end

---
-- Verifica se duas entradas de ofertas com propriedades
-- formadas pelo RSFacet:createPropertyIndex s�o equivalentes.
--
-- @param offerEntryA Oferta a ser comparada
-- @param offerEntryB Oferta a ser comparada
--
-- @return true se as ofertas pertencem ao mesmo membro com as mesmas propriedades.
--  false em caso contr�rio.
--
function equalsOfferEntries(offerEntryA, offerEntryB)
  -- (A contido em B) ^ (B contido A) -> (A == B)
  return offerEntryA.credential.identifier == offerEntryB.credential.identifier and
    containsProperties(offerEntryA.properties, offerEntryB.properties)          and
    containsProperties(offerEntryB.properties, offerEntryA.properties)
end

---
-- Verifica se o primeiro conjunto de propriedades cont�m o segundo.
--
-- Essas propriedades s�o o resultado da fun��o RSFacet:createPropertyIndex().
-- Ela ignora as propriedades 'component_id' e 'registered_by' que s�o geradas
-- automaticamente, comparando somente os dados fornecidos pelo membro.
--
-- @param propertiesA Propriedades de registro
-- @param propertiesB Propriedades de registro
--
-- @return true se propertiesA cont�m propertiesB. false, caso contr�rio.
--
function containsProperties(propertiesA, propertiesB)
   for name, values in pairs(propertiesB) do
     -- Propriedades registradas automaticamente pelo Servi�o de Registro: ignorar
     if name ~= "component_id" and name ~= "registered_by" then 
       for value in pairs(values) do
         if not (propertiesA[name] and propertiesA[name][value]) then
           return false
         end
       end
     end
   end
   return true
end

-- Parser de uma string serializada de descricoes de facetas
-- onde o divisor de cada descricao eh o caracter '#'
-- @return Retorna uma tabela da seguinte forma:
--    facets[facet.name] = true
--    facets[facet.interface_name] = true
--    facets[facet.facet_ref] = true
function unmarshalHashFacets(strFacets)
  local facets = {}
  for facetDesc in string.gmatch(strFacets, "[^#]+") do
    facets[facetDesc] = true
  end
  return facets
end

function marshalHashFacets(facets)
    local strFacets = ""
    for facetDesc, value in ipairs(facets) do
        strFacets = strFacets .. "#" .. facetDesc
    end
    return strFacets
end


patt="%-?%-?(%w+)(=?)(.*)"
-- Parsing arguments and returns a 'table[option]=value'
function parse_args(arg, usage_msg, allowempty)
  assert(type(arg)=="table","ERROR: Missing arguments! This program should be loaded from console.")
  local arguments = {}
  -- concatenates with the custom usage_msg
  usage_msg=[[
 Usage: ]]..arg[0]..[[ OPTIONS
 Valid OPTIONS:
]] ..usage_msg

  if not (arg[1]) and not allowempty then print(usage_msg) ; os.exit(1) end

  for i,param in ipairs(arg) do
    local opt,_,value = param:match(patt)
    if opt == "h" or opt == "help" then
      print(usage_msg)
      os.exit(1)
    end
    if opt and value then
      if arguments[opt] then
        arguments[opt] = arguments[opt].." "..value
      else
        arguments[opt] = value
      end
    end
  end

  return arguments
end




