local msg = require "openbus.core.messages"

msg.OpenBusVersion = "2.0"

-- openbus.core.bin.openbus
msg.CopyrightNotice = "Openbus "..msg.OpenBusVersion.."  Copyright (C) 2011 Tecgraf, PUC-Rio"
msg.BusSuccessfullyStarted = "OpenBus "..msg.OpenBusVersion.." iniciado com sucesso"

-- openbus.core.services.AccessControl
msg.NoPasswordValidators = "nenhum validador de senha foi especificado"
msg.RegisterEntityCertificate = "registro de certificado de '$entity'"
msg.RecoverEntityCertificate = "recuperação certificado de '$entity'"
msg.RemoveEntityCertificate = "remoção certificado de '$entity'"
msg.LoginByCertificate = "login por certificado de '$entity' (id=$login)"
msg.LoginByPassword = "login por senha de '$entity' validado por '$validator' (id=$login)"
msg.FailedPasswordValidation = "senha de '$entity' não foi validada por '$validator' ($errmsg)"
msg.LoginExpired = "expiração de login de '$entity' (id=$login)"
msg.LoginByCertificateExpired = "expiração do processo de login por certificado de '$entity'"
msg.LoginByCertificateInitiated = "iniciação do processo de login por certificado de '$entity'"
msg.LogoutPerformed = "logout de '$entity' (id=$login)"
msg.LoginRenewed = "renovação de login de '$entity' (id=$login)"
msg.LoginObserverException = "falha na notificação de observador de login ($errmsg)"
msg.LogoutForced = "encerramento forçado do login de '$entity' (id=$login)"

-- openbus.core.services.OfferRegistry
--msg.UpdateOfferProperties = "$offer"
--msg.RemoveServiceOffer = "$offer"
--msg.RemoveOfferAfterOwnerLogoff = "$offer $entity $login"
--msg.RecoverPersistedOffer = "$offer $entity $login"
--msg.CorruptedDatabaseDueToMissingEntity = "$entity"
--msg.DiscardPersistedOfferAfterLogout = "$offer $entity $login"
--msg.RegisterServiceOffer = "$offer $entity $login"
--msg.CorruptedDatabaseDueToMissingCategory = "$category"

-- openbus.core.services.passwordvalidator.LDAP
msg.LdapBadServerSpec = "o servidor LDAP '$actual' é inválido (formato esperado é '<host>:<porta>')"
msg.LdapNoServers = "nenhum servidor LDAP configurado"
msg.LdapAccessAttemptFailed = "\n\tlogin '$user': $errmsg"
msg.LdapAccessFailed = "usuário '$user': $errmsg"

return msg
