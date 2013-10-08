local array = require "table"
local concat = array.concat

local idl = require "openbus.core.idl"
local msg = require "openbus.core.messages"

msg.ReleaseVersion = 0
msg.PatchVersion = 2

msg.OpenBusVersion = concat({
  idl.const.MajorVersion,
  idl.const.MinorVersion,
  msg.ReleaseVersion
}, ".")
if msg.PatchVersion > 0 then
  msg.OpenBusVersion = msg.OpenBusVersion.."_"..msg.PatchVersion
end

-- openbus.core.services.main
msg.CopyrightNotice = "OpenBus "..msg.OpenBusVersion.."  Copyright (C) 2012-2013 Tecgraf, PUC-Rio"
--msg.CoreServicesStarted = "serviços núcleo iniciados"
--msg.RequestedByEntity = "por $entity (login=$login)"
--
---- openbus.core.services.AccessControl
--msg.NoPasswordValidators = "nenhum validador de senha foi especificado"
--msg.RegisterEntityCertificate = "registro de certificado de $entity"
--msg.RecoverEntityCertificate = "recuperação certificado de $entity"
--msg.RemoveEntityCertificate = "remoção certificado de $entity  "
--msg.LoginByCertificate = "login por certificado de $entity (login=$login)"
--msg.LoginByPassword = "login por senha de $entity validado por $validator (login=$login)"
--msg.FailedPasswordValidation = "senha de $entity não foi validada por $validator: $errmsg"
--msg.LoginExpired = "expiração de login de $entity (login=$login)"
--msg.LoginByCertificateExpired = "expiração do processo de login por certificado de $entity"
--msg.LoginByCertificateInitiated = "iniciação do processo de login por certificado de $entity"
--msg.LogoutPerformed = "logout de $entity (login=$login)"
--msg.LoginRenewed = "renovação de login de $entity (login=$login)"
--msg.LoginObserverException = "falha na notificação de observador de login: $errmsg"
--msg.LogoutForced = "encerramento forçado do login de $entity (login=$login)"
--
---- openbus.core.services.OfferRegistry
----msg.UpdateOfferProperties = "$offer"
----msg.RemoveServiceOffer = "$offer"
----msg.RemoveOfferAfterOwnerLogoff = "$offer $entity $login"
----msg.RecoverPersistedOffer = "$offer $entity $login"
----msg.CorruptedDatabaseDueToMissingEntity = "$entity"
----msg.DiscardPersistedOfferAfterLogout = "$offer $entity $login"
----msg.RegisterServiceOffer = "$offer $entity $login"
----msg.CorruptedDatabaseDueToMissingCategory = "$category"
--msg.OfferRegistrationObserverException = "falha na notificação de observador de registro de ofertas (cookie=$cookie): $errmsg"
--msg.OfferObserverException = "falha na notificação de observador de ofertas (cookie=$cookie): $errmsg"
--
---- openbus.core.services.passwordvalidator.LDAP
--msg.LdapBadPatternSpec = "nenhum padrão válido de formação de logins LDAP (formato esperado é uma lista de strings mas foi fornecido um tipo $type)"
--msg.LdapNoServers = "nenhum servidor LDAP configurado"
--msg.LdapAccessAttemptFailed = "falha na tentativa de login (user=$user,server=$server,ldaperr=$errmsg)"
--msg.LdapAccessFailed = "falha no acesso LDAP: $errmsg"

return msg
