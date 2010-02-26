/*
** interceptors/ServerInterceptor.cpp
*/

#include "ServerInterceptor.h"
#include "../../openbus.h"

namespace openbus {
  namespace interceptors {
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

    ServerInterceptor::~ServerInterceptor() {}

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
    #ifdef OPENBUS_MICO
      if (bus->getAccessControlService()->isValid(c)) {
    #else
      if (bus->getAccessControlService()->isValid(*c)) {
    #endif
        picurrent->set_slot(slotid, any);
      } else {
        Openbus::logger->log(ERROR, "Throwing CORBA::NO_PERMISSION...");
        Openbus::logger->dedent(INFO, "ServerInterceptor::receive_request() END");
        throw CORBA::NO_PERMISSION();
      }
      Openbus::logger->dedent(INFO, "ServerInterceptor::receive_request() END");
    }
    void ServerInterceptor::receive_request_service_contexts(ServerRequestInfo*)
      {}
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
  }
}
