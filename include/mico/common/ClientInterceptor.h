/*
** mico/common/ClientInterceptor.h
*/

#ifndef CLIENTINTERCEPTOR_H_
#define CLIENTINTERCEPTOR_H_

#include <string.h>
#include <CORBA.h>

using namespace PortableInterceptor ;

namespace clientinterceptor {

  struct CredentialHolder {
    const char* identifier ;
    const char* entityName ;
  } ;

  class ClientInterceptor : public ClientRequestInterceptor {
    private:
      CredentialHolder* credentialHolder ;
      void fillWExtraByte( IOP::ServiceContext::_context_data_seq &ctx, \
                           int* idx, unsigned long alignment ) ;
    public:
      ClientInterceptor( CredentialHolder &pcredentialHolder ) ;
      ~ClientInterceptor() ;
      void send_request( ClientRequestInfo_ptr ri ) ;
      void send_poll( ClientRequestInfo_ptr ri ) ;
      void receive_reply( ClientRequestInfo_ptr ri ) ;
      void receive_exception( ClientRequestInfo_ptr ri ) ;
      void receive_other( ClientRequestInfo_ptr ri ) ;
      char* name() ;
      void destroy() ;
  } ;
}

#endif
