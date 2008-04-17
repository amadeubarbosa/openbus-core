/*
** common/ServerInterceptor.cpp
*/

#include "ServerInterceptor.h"

#ifdef VERBOSE
  #include <iostream>
  #include <string.h>
#endif

#include <mico/pi_impl.h>

#ifdef VERBOSE
  using namespace std ;
#endif

namespace openbus {
  namespace common {
    ServerInterceptor::ServerInterceptor( Current* ppicurrent, \
                                          SlotId pslotid )
    {
      slotid = pslotid ;
      picurrent = ppicurrent ;
    }

    ServerInterceptor::~ServerInterceptor() {}

    void ServerInterceptor::receive_request( ServerRequestInfo_ptr ri ) {
      ::IOP::ServiceContext* sc = ri->get_request_service_context(1234);
    #ifdef VERBOSE
      cout << "[Receive a request: " << ri->operation() << "]" << endl ;
      CORBA::ULong z ;
      cout << "[Context Data:]" ;
      for ( z = 0; z < sc->context_data.length(); z++ ) {
        printf( "%u ", sc->context_data[ z ] ) ;
      }
    #endif
      ::PICodec::Codec_impl* co = new ::PICodec::Codec_impl;

      CORBA::Any_var any = co->decode_value( sc->context_data, openbusidl::acs::_tc_Credential ) ;
      picurrent->set_slot( slotid, any ) ;

    #ifdef VERBOSE
      openbusidl::acs::Credential_var c = new openbusidl::acs::Credential ;
      any >>= c ;
      cout << "[credential->entityName: " << c->entityName.in() << "]" << endl ;
      cout << "[credential->identifier: " << c->identifier.in() << "]" << endl ;
    #endif
    }
    void ServerInterceptor::receive_request_service_contexts( ServerRequestInfo* ) {}
    void ServerInterceptor::send_reply( ServerRequestInfo* ) {}
    void ServerInterceptor::send_exception( ServerRequestInfo* ) {}
    void ServerInterceptor::send_other( ServerRequestInfo* ) {}

    char* ServerInterceptor::name() {
      return "" ;
    }

    void ServerInterceptor::destroy() {}

    openbusidl::acs::Credential_var ServerInterceptor::getCredential() {
      CORBA::Any_var any = picurrent->get_slot( slotid ) ;
      openbusidl::acs::Credential_var cr = new openbusidl::acs::Credential ;
      any >>= cr ;
      return cr._retn() ;
    }
  }
}
