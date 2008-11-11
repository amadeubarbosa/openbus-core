/*
** common/ServerInterceptor.cpp
*/

#include "ServerInterceptor.h"

#ifdef VERBOSE
  #include <iostream>
  #include <string.h>
#endif

#ifdef VERBOSE
  using namespace std;
#endif

namespace openbus {
  namespace common {
    ServerInterceptor::ServerInterceptor(Current* ppicurrent, \
                                          SlotId pslotid, \
                                          IOP::Codec_ptr pcdr_codec)
    {
    #ifdef VERBOSE
      cout << "\n\n[ServerInterceptor::ServerInterceptor() BEGIN]" << endl;
    #endif
      slotid = pslotid;
      picurrent = ppicurrent;
      cdr_codec = pcdr_codec;
    #ifdef VERBOSE
      cout << "\n\n[ServerInterceptor::ServerInterceptor() END]" << endl;
    #endif
    }

    ServerInterceptor::~ServerInterceptor() {}

    void ServerInterceptor::receive_request(ServerRequestInfo_ptr ri) {
      ::IOP::ServiceContext* sc = ri->get_request_service_context(1234);
    #ifdef VERBOSE
      cout << "[Receive a request: " << ri->operation() << "]" << endl;
      CORBA::ULong z;
      cout << "[Context Data:]";
      for (z = 0; z < sc->context_data.length(); z++) {
        printf("%u ", sc->context_data[ z ]);
      }
    #endif

      IOP::ServiceContext::_context_data_seq& context_data = sc->context_data;

      CORBA::OctetSeq octets(context_data.length(),
                   context_data.length(),
                   context_data.get_buffer(),
                   IT_FALSE);

      CORBA::Any_var any = cdr_codec->decode_value(octets, openbusidl::acs::_tc_Credential);
      picurrent->set_slot(slotid, any);

    #ifdef VERBOSE
      openbusidl::acs::Credential* c = new openbusidl::acs::Credential;
      any >>= c;
      cout << "[credential->owner: " << c->owner << "]" << endl;
      cout << "[credential->identifier: " << c->identifier << "]" << endl;
      cout << "[credential->delegate: " << c->delegate << "]" << endl;
    #endif
    }
    void ServerInterceptor::receive_request_service_contexts(ServerRequestInfo*) {}
    void ServerInterceptor::send_reply(ServerRequestInfo*) {}
    void ServerInterceptor::send_exception(ServerRequestInfo*) {}
    void ServerInterceptor::send_other(ServerRequestInfo*) {}

    char* ServerInterceptor::name() {
      return CORBA::it_string_dup_eh("AccessControl");
    }

    void ServerInterceptor::destroy() {}

    openbusidl::acs::Credential_var ServerInterceptor::getCredential() {
    #ifdef VERBOSE
      cout << "\n\n[ServerInterceptor::getCredential() BEGIN]" << endl;
    #endif
      CORBA::Any_var any = picurrent->get_slot(slotid);
      openbusidl::acs::Credential* c = new openbusidl::acs::Credential;
      any >>= c;
    #ifdef VERBOSE
      cout << "\t[credential->owner: " << c->owner << "]" << endl;
      cout << "\t[credential->identifier: " << c->identifier << "]" << endl;
      cout << "\t[credential->delegate: " << c->delegate << "]" << endl;
      cout << "[ServerInterceptor::getCredential() END]" << endl;
    #endif
      openbusidl::acs::Credential_var ret = new openbusidl::acs::Credential;
      ret->owner = c->owner;
      ret->identifier = c->identifier;
      ret->delegate = c->delegate;
      return ret._retn();
    }
  }
}
