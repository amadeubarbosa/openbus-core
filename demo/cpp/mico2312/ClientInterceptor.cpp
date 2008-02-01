/*
** ClientInterceptor.cpp
*/

#include "mico/common/ClientInterceptor.h"

#include <iostream>
#include <mico/pi.h>
#include <mico/pi_impl.h>
#include <mico/codec_impl.h>

#define CORBAULONG_LEN 4
#define EXTRABYTE 0x00

using namespace std ;

namespace clientinterceptor {

  void ClientInterceptor::fillWExtraByte( IOP::ServiceContext::_context_data_seq &ctx, int* idx, unsigned long alignment
)
  {
    while (true) {
      if ( (*idx % alignment) != 0 ) {
        ctx[ *idx ] = EXTRABYTE ;
        *idx = *idx + 1 ;
      } else {
        break ;
      }
    }
  }

  ClientInterceptor::ClientInterceptor( CredentialHolder &pcredentialHolder ) {
  #ifdef VERBOSE
    cout << "\n\n[ClientInterceptor::ClientInterceptor() BEGIN]" << endl ;
  #endif
    credentialHolder = &pcredentialHolder ;
    credentialHolder->identifier = "" ;
    credentialHolder->entityName = "" ;
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
    IOP::ServiceContext sc ;
    sc.context_id = 1234 ;

    MICO::CDREncoder encoder ;

    encoder.put_string( credentialHolder->identifier ) ;
    encoder.put_string( credentialHolder->entityName ) ;
    CORBA::Octet* octs = encoder.buffer()->data() ;
    unsigned long alignment = encoder.max_alignment() - CORBAULONG_LEN ;
    int idx = 0 ;

    unsigned long buffer_len = encoder.buffer()->length() ;
    sc.context_data.length( 1 + (alignment - 1) + buffer_len ) ;

  /* ContextData Stream:
  **  <byteOrder> <alignment> <stringLen> <string> .....
  */
    sc.context_data[ 0 ] = encoder.byteorder() ;
    idx++ ;
    fillWExtraByte( sc.context_data, &idx, alignment ) ;

    memcpy( &sc.context_data[idx], octs, (buffer_len-1) ) ;

  #ifdef VERBOSE
    CORBA::ULong z ;
    cout << "[Context Data:]" ;
    for ( z = 0; z < sc.context_data.length(); z++ ) {
      printf( "%u ", sc.context_data[ z ] ) ;
    }
  #endif

    ri->add_request_service_context( sc, true ) ;
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
