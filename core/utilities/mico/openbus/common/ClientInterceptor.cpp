/*
** common/ClientInterceptor.cpp
*/

#include "ClientInterceptor.h"

#ifdef VERBOSE
  #include <iostream>
#endif

#include <mico/pi_impl.h>
#include <mico/codec_impl.h>

#include "../../stubs/access_control_service.h"

using namespace openbusidl::acs;
#ifdef VERBOSE
  using namespace std ;
#endif

namespace openbus {
  namespace common {
    ClientInterceptor::ClientInterceptor( CredentialManager* pcredentialManager ) {
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::ClientInterceptor() BEGIN]" << endl ;
    #endif
      credentialManager = pcredentialManager ;
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::ClientInterceptor() END]" << endl ;
    #endif
    }

    ClientInterceptor::~ClientInterceptor() {
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::~ClientInterceptor() BEGIN]" << endl ;
    #endif
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::~ClientInterceptor() END]" << endl ;
    #endif
    }

    void ClientInterceptor::send_request( ClientRequestInfo_ptr ri )
    {
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::send_request() BEGIN]" << endl ;
    #endif
      Credential* c = credentialManager->getValue() ;
      if ( c != NULL ) {
        IOP::ServiceContext sc ;
        sc.context_id = 1234 ;

        MICO::CDREncoder encoder ;

        CORBA::Any any ;
        any <<= *c ;
        CORBA::OctetSeq_var en ;
        PICodec::Codec_impl* codec = new PICodec::Codec_impl ;
        en = codec->encode_value( any ) ;

        sc.context_data = en ;

      #ifdef VERBOSE
        CORBA::ULong z ;
        cout << "[Context Data:]" ;
        for ( z = 0; z < sc.context_data.length(); z++ ) {
          printf( "%u ", sc.context_data[ z ] ) ;
        }
      #endif

        ri->add_request_service_context( sc, true ) ;
      }
    #ifdef VERBOSE
      cout << "\n[ClientInterceptor::send_request() END]" << endl ;
    #endif
    }

    char* ClientInterceptor::name() { return "" ; }
    void ClientInterceptor::destroy() {}
    void ClientInterceptor::send_poll( ClientRequestInfo_ptr ri ) {}
    void ClientInterceptor::receive_reply( ClientRequestInfo_ptr ri ) {}
    void ClientInterceptor::receive_exception( ClientRequestInfo_ptr ri ) {}
    void ClientInterceptor::receive_other( ClientRequestInfo_ptr ri ) {}
  }
}
