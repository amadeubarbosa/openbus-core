/*
** common/ServerInterceptor.cpp
*/

#include "ServerInterceptor.h"
#include "../../openbus.h"

#ifdef VERBOSE
  #include <iostream>
  #include <string.h>
#endif

namespace openbus {
  namespace common {
    ServerInterceptor::ServerInterceptor(
      Current* ppicurrent,
      SlotId pslotid,
      IOP::Codec_ptr pcdr_codec)
    {
    #ifdef VERBOSE
      Openbus::verbose->print("ServerInterceptor::ServerInterceptor() BEGIN");
      Openbus::verbose->indent();
    #endif
      slotid = pslotid;
      picurrent = ppicurrent;
      cdr_codec = pcdr_codec;
    #ifdef VERBOSE
      Openbus::verbose->dedent("ServerInterceptor::ServerInterceptor() END");
    #endif
    }

    ServerInterceptor::~ServerInterceptor() {}

    void ServerInterceptor::receive_request(ServerRequestInfo_ptr ri) {
      ::IOP::ServiceContext_var sc = ri->get_request_service_context(1234);
    #ifdef VERBOSE
      Openbus::verbose->print("ServerInterceptor::receive_request() BEGIN");
      Openbus::verbose->indent();
//      stringstream request;
//      request << "Receive a request: " << ri->operation();
//      Openbus::verbose->print(request.str());
      CORBA::ULong z;
      stringstream contextData;
      contextData << "Context Data: ";
      for (z = 0; z < sc->context_data.length(); z++) {
        contextData << (unsigned) sc->context_data[z];
      }
      Openbus::verbose->print(contextData.str());
    #endif

      IOP::ServiceContext::_context_data_seq& context_data = sc->context_data;

      CORBA::OctetSeq octets(context_data.length(),
                   context_data.length(),
                   context_data.get_buffer(),
                   IT_FALSE);

      CORBA::Any_var any = cdr_codec->decode_value(
        octets, 
        openbusidl::acs::_tc_Credential);
      openbusidl::acs::Credential* c;
      any >>= c;
    #ifdef VERBOSE
      Openbus::verbose->print("credential->owner: " + (string) c->owner);
      Openbus::verbose->print("credential->identifier: " + 
        (string) c->identifier);
      Openbus::verbose->print("credential->delegate: " + 
        (string) c->delegate);
    #endif
      openbus::Openbus* bus = openbus::Openbus::getInstance();
      if (bus->getAccessControlService()->isValid(*c)) {
        picurrent->set_slot(slotid, any);
      } else {
      #ifdef VERBOSE
        Openbus::verbose->print("Throwing CORBA::NO_PERMISSION...");
        Openbus::verbose->dedent("ServerInterceptor::receive_request() END");
      #endif
        throw CORBA::NO_PERMISSION();
      }
    #ifdef VERBOSE
      Openbus::verbose->dedent("ServerInterceptor::receive_request() END");
    #endif
    }
    void ServerInterceptor::receive_request_service_contexts(ServerRequestInfo*)
      {}
    void ServerInterceptor::send_reply(ServerRequestInfo*) {}
    void ServerInterceptor::send_exception(ServerRequestInfo*) {}
    void ServerInterceptor::send_other(ServerRequestInfo*) {}

    char* ServerInterceptor::name() {
      return CORBA::it_string_dup_eh("AccessControl");
    }

    void ServerInterceptor::destroy() {}

    openbusidl::acs::Credential_var ServerInterceptor::getCredential() {
    #ifdef VERBOSE
      Openbus::verbose->print("ServerInterceptor::getCredential() BEGIN");
      Openbus::verbose->indent();
    #endif
      CORBA::Any_var any = picurrent->get_slot(slotid);

      openbusidl::acs::Credential* c = 0;
      any >>= c;
      if (c) {
      #ifdef VERBOSE
        Openbus::verbose->print("credential->owner: " + (string) c->owner);
        Openbus::verbose->print("credential->identifier: " + 
          (string) c->identifier);
        Openbus::verbose->print("credential->delegate: " + 
          (string) c->delegate);
      #endif
        openbusidl::acs::Credential_var ret = 
          new openbusidl::acs::Credential();
        ret->owner = CORBA::string_dup(c->owner);
        ret->identifier = CORBA::string_dup(c->identifier);
        ret->delegate = CORBA::string_dup(c->delegate);
      #ifdef VERBOSE
        Openbus::verbose->dedent("ServerInterceptor::getCredential() END");
      #endif
        return ret._retn();
      } else {
      #ifdef VERBOSE
        Openbus::verbose->dedent("ServerInterceptor::getCredential() END");
      #endif
        return 0;
      }
    }
  }
}
