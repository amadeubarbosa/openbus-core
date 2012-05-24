local msg = require "openbus.core.messages"

msg.OpenBusVersion = "2.0"

-- openbus.core.bin.openbus
msg.CopyrightNotice = "OpenBus "..msg.OpenBusVersion.."  Copyright (C) 2011 Tecgraf, PUC-Rio"
msg.BusSuccessfullyStarted = "OpenBus "..msg.OpenBusVersion.." iniciado com sucesso"

-- openbus.core.services.AccessControl
msg.NoPasswordValidators = "nenhum validador de senha foi especificado"
msg.RegisterEntityCertificate = "registro de certificado de $entity"
msg.RecoverEntityCertificate = "recupera��o certificado de $entity"
msg.RemoveEntityCertificate = "remo��o certificado de $entity  "
msg.LoginByCertificate = "login por certificado de $entity (login=$login)"
msg.LoginByPassword = "login por senha de $entity validado por $validator (login=$login)"
msg.FailedPasswordValidation = "senha de $entity n�o foi validada por $validator: errmsg"
msg.LoginExpired = "expira��o de login de $entity (login=$login)"
msg.LoginByCertificateExpired = "expira��o do processo de login por certificado de $entity"
msg.LoginByCertificateInitiated = "inicia��o do processo de login por certificado de $entity"
msg.LogoutPerformed = "logout de $entity (login=$login)"
msg.LoginRenewed = "renova��o de login de $entity (login=$login)"
msg.LoginObserverException = "falha na notifica��o de observador de login: $errmsg"
msg.LogoutForced = "encerramento for�ado do login de $entity (login=$login)"

-- openbus.core.services.OfferRegistry
--msg.UpdateOfferProperties = "$offer"
--msg.RemoveServiceOffer = "$offer"
--msg.RemoveOfferAfterOwnerLogoff = "$offer $entity $login"
--msg.RecoverPersistedOffer = "$offer $entity $login"
--msg.CorruptedDatabaseDueToMissingEntity = "$entity"
--msg.DiscardPersistedOfferAfterLogout = "$offer $entity $login"
--msg.RegisterServiceOffer = "$offer $entity $login"
--msg.CorruptedDatabaseDueToMissingCategory = "$category"
msg.OfferRegistrationObserverException = "falha na notifica��o de observador de registro de ofertas (id=$id): $errmsg"
msg.OfferObserverException = "falha na notifica��o de observador de ofertas (id=$id): $errmsg"

-- openbus.core.services.passwordvalidator.LDAP
msg.LdapBadServerSpec = "o servidor LDAP $actual � inv�lido (formato esperado � '<host>:<porta>')"
msg.LdapNoServers = "nenhum servidor LDAP configurado"
msg.LdapAccessAttemptFailed = "\n\tlogin $user: $errmsg"
msg.LdapAccessFailed = "usu�rio $user: $errmsg"

return msg
