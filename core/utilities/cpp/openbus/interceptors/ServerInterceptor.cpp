/*
** interceptors/ServerInterceptor.cpp
*/

#include "ServerInterceptor.h"
#include "../../openbus.h"

namespace openbus {
  namespace interceptors {
  #ifdef OPENBUS_MICO
    unsigned long ServerInterceptor::validationTime = 30000;
    set<access_control_service::Credential>::iterator 
      ServerInterceptor::itCredentialsCache;
    set<access_control_service::Credential, 
      ServerInterceptor::setCredentialCompare> 
      ServerInterceptor::credentialsCache;

    ServerInterceptor::CredentialsValidationCallback::
      CredentialsValidationCallback() {
    };

    void ServerInterceptor::CredentialsValidationCallback::callback(
      CORBA::Dispatcher* dispatcher, 
      Event event)
    {
      Openbus::logger->log(INFO, 
        "ServerInterceptor::CredentialsValidationCallback() BEGIN");
      Openbus::logger->indent();
      openbus::Openbus* bus = openbus::Openbus::getInstance();
      access_control_service::IAccessControlService* iAccessControlService = 
        bus->getAccessControlService();
      for (itCredentialsCache = credentialsCache.begin();
           itCredentialsCache != credentialsCache.end(); 
           itCredentialsCache++)
      {
        stringstream out;
        out << "Validando a credencial: " << 
          (const char*) ((*itCredentialsCache).identifier) << " ...";
        Openbus::logger->log(INFO, out.str());
        try {
          if (iAccessControlService->isValid(*itCredentialsCache)) {
            Openbus::logger->log(INFO, "Credencial ainda é válida.");
          } else {
            Openbus::logger->log(WARNING, "Credencial NÃO é mais válida!");
            credentialsCache.erase(itCredentialsCache);
          }
        } catch (CORBA::SystemException& e) {
          Openbus::logger->log(ERROR, 
            "Erro ao verificar validade da credencial");
        }
      }
      dispatcher->tm_event(this, validationTime);
      Openbus::logger->dedent(INFO, 
        "ServerInterceptor::CredentialsValidationCallback() END");
    }
  #endif
    ServerInterceptor::ServerInterceptor(
      Current* ppicurrent,
      SlotId pslotid,
      IOP::Codec_ptr pcdr_codec)
    {
      Openbus::logger->log(INFO, "ServerInterceptor::ServerInterceptor() BEGIN");
      Openbus::logger->indent();
      slotid = pslotid;
      picurrent = ppicurrent;
      cdr_codec = pcdr_codec;
      Openbus::logger->dedent(INFO, "ServerInterceptor::ServerInterceptor() END");
    }

    ServerInterceptor::~ServerInterceptor() {
    #ifdef OPENBUS_MICO
      openbus::Openbus* bus = openbus::Openbus::getInstance();
      bus->getORB()->dispatcher()->remove(&credentialsValidationCallback, 
        CORBA::Dispatcher::Timer);
    #endif
    }

    void ServerInterceptor::receive_request(ServerRequestInfo_ptr ri) {
      ::IOP::ServiceContext_var sc = ri->get_request_service_context(1234);
      Openbus::logger->log(INFO, "ServerInterceptor::receive_request() BEGIN");
      Openbus::logger->indent();
      stringstream request;
      char * operation = ri->operation();
      request << "Receive a request: " << operation;
      Openbus::logger->log(INFO, request.str());
      free(operation);
      CORBA::ULong z;
      stringstream contextData;
      contextData << "Context Data: ";
      for (z = 0; z < sc->context_data.length(); z++) {
        contextData << (unsigned) sc->context_data[z];
      }
      Openbus::logger->log(INFO, contextData.str());

      IOP::ServiceContext::_context_data_seq& context_data = sc->context_data;

      CORBA::OctetSeq octets(context_data.length(),
                   context_data.length(),
                   
                   context_data.get_buffer(),
                   0);

      CORBA::Any_var any = cdr_codec->decode_value(
        octets, 
        access_control_service::_tc_Credential);
    #ifdef OPENBUS_MICO
      access_control_service::Credential c;
    #else
      access_control_service::Credential* c;
    #endif
      any >>= c;
    #ifdef OPENBUS_MICO
      Openbus::logger->log(INFO, "credential->owner: " + (string) c.owner);
      Openbus::logger->log(INFO, "credential->identifier: " + 
        (string) c.identifier);
      Openbus::logger->log(INFO, "credential->delegate: " + 
        (string) c.delegate);
    #else
      Openbus::logger->log(INFO, "credential->owner: " + (string) c->owner);
      Openbus::logger->log(INFO, "credential->identifier: " + 
        (string) c->identifier);
      Openbus::logger->log(INFO, "credential->delegate: " + 
        (string) c->delegate);
    #endif
      openbus::Openbus* bus = openbus::Openbus::getInstance();
      CredentialValidationPolicy policy = 
        bus->getCredentialValidationPolicy(); 
      picurrent->set_slot(slotid, any);
      if (policy == ALWAYS) {
        Openbus::logger->log(INFO, "Política de renovação de credenciais: " + 
          (string) + "ALWAYS");
        Openbus::logger->log(INFO, "Validando credencial REMOTAMENTE...");
        try {
        #ifdef OPENBUS_MICO
          if (bus->getAccessControlService()->isValid(c)) {
        #else
          if (bus->getAccessControlService()->isValid(*c)) {
        #endif
            Openbus::logger->log(INFO, "Credencial renovada.");
            Openbus::logger->dedent(INFO,
              "ServerInterceptor::receive_request() END");
          } else {
            Openbus::logger->log(INFO, "Falha na renovação da credencial.");
            Openbus::logger->log(ERROR, "Throwing CORBA::NO_PERMISSION...");
            Openbus::logger->dedent(INFO,
              "ServerInterceptor::receive_request() END");
            throw CORBA::NO_PERMISSION();
          }
        } catch (CORBA::SystemException& e) {
          Openbus::logger->log(INFO, "Falha na renovação da credencial.");
          Openbus::logger->log(ERROR, "Throwing CORBA::SystemException");
          Openbus::logger->dedent(INFO,
            "ServerInterceptor::receive_request() END");
          throw;
        }
    #ifdef OPENBUS_MICO
      } else if (policy == CACHED) {
        Openbus::logger->log(INFO, "Política de renovação de credenciais: " + 
          (string) "CACHED");
        stringstream out;
        out << "Número de credenciais no cache: " << credentialsCache.size();
        Openbus::logger->log(INFO, out.str());
        if (credentialsCache.find(c) != credentialsCache.end()
            &&
            !credentialsCache.empty()) 
        {  
          Openbus::logger->log(INFO, "Credencial está no cache.");
          Openbus::logger->dedent(INFO, 
            "ServerInterceptor::receive_request() END");
        } else {
          Openbus::logger->log(INFO, "Credencial NÃO está no cache.");
          Openbus::logger->log(INFO, "Validando credencial no ACS...");
          try {
          #ifdef OPENBUS_MICO
            if (bus->getAccessControlService()->isValid(c)) {
          #else
            if (bus->getAccessControlService()->isValid(*c)) {
          #endif
              Openbus::logger->log(INFO, "Credencial validada.");
            } else {
              Openbus::logger->log(INFO, "Falha na validação da credencial.");
              Openbus::logger->log(ERROR, "Throwing CORBA::NO_PERMISSION...");
              Openbus::logger->dedent(INFO,
                "ServerInterceptor::receive_request() END");
              throw CORBA::NO_PERMISSION();
            }
            Openbus::logger->log(INFO, "Inserindo credencial no cache...");
            credentialsCache.insert(c);
            Openbus::logger->dedent(INFO, 
              "ServerInterceptor::receive_request() END");
          } catch (CORBA::SystemException& e) {
            Openbus::logger->log(INFO, "Falha na validação da credencial.");
            Openbus::logger->log(ERROR, "Throwing CORBA::SystemException");
            Openbus::logger->dedent(INFO,
              "ServerInterceptor::receive_request() END");
            throw;
          }
        }
    #endif
      } else {
        Openbus::logger->log(INFO, "Política de renovação de credenciais: " + 
          (string) "NONE");
        Openbus::logger->dedent(INFO, 
          "ServerInterceptor::receive_request() END");
      }
    }          
      
    void ServerInterceptor::receive_request_service_contexts(
      ServerRequestInfo*) {
    }

    void ServerInterceptor::send_reply(ServerRequestInfo*) {}

    void ServerInterceptor::send_exception(ServerRequestInfo*) {}

    void ServerInterceptor::send_other(ServerRequestInfo*) {}

    char* ServerInterceptor::name() {
    #ifdef OPENBUS_MICO
      return "AccessControl";
    #else
      return CORBA::string_dup("AccessControl");
    #endif
    }

    void ServerInterceptor::destroy() {}

    access_control_service::Credential_var ServerInterceptor::getCredential() {
      Openbus::logger->log(INFO, "ServerInterceptor::getCredential() BEGIN");
      Openbus::logger->indent();
      CORBA::Any_var any = picurrent->get_slot(slotid);

    #ifdef OPENBUS_MICO
      access_control_service::Credential c;
      if (any >>=c) {
        Openbus::logger->log(INFO, "credential->owner: " + (string) c.owner);
        Openbus::logger->log(INFO, "credential->identifier: " + 
          (string) c.identifier);
        Openbus::logger->log(INFO, "credential->delegate: " + 
          (string) c.delegate);
        access_control_service::Credential_var ret = 
          new access_control_service::Credential();
        ret->owner = CORBA::string_dup(c.owner);
        ret->identifier = CORBA::string_dup(c.identifier);
        ret->delegate = CORBA::string_dup(c.delegate);
    #else
      access_control_service::Credential* c = 0;
      any >>= c;
      if (c) {
        Openbus::logger->log(INFO, "credential->owner: " + (string) c->owner);
        Openbus::logger->log(INFO, "credential->identifier: " + 
          (string) c->identifier);
        Openbus::logger->log(INFO, "credential->delegate: " + 
          (string) c->delegate);
        access_control_service::Credential_var ret = 
          new access_control_service::Credential();
        ret->owner = CORBA::string_dup(c->owner);
        ret->identifier = CORBA::string_dup(c->identifier);
        ret->delegate = CORBA::string_dup(c->delegate);
    #endif
        Openbus::logger->dedent(INFO, "ServerInterceptor::getCredential() END");
        return ret._retn();
      } else {
        Openbus::logger->dedent(INFO, "ServerInterceptor::getCredential() END");
        return 0;
      }
    }

  #ifdef OPENBUS_MICO
    void ServerInterceptor::registerValidationDispatcher() {
      openbus::Openbus* bus = openbus::Openbus::getInstance();
      bus->getORB()->dispatcher()->tm_event(&credentialsValidationCallback, 
        validationTime);
    }

    void ServerInterceptor::setValidationTime(unsigned long pValidationTime) {
      validationTime = pValidationTime;
    }


    unsigned long ServerInterceptor::getValidationTime() {
      return validationTime;
    }
  #endif
  }
}
