/*
** mico/common/ClientInterceptor.h
*/

#ifndef CLIENTINTERCEPTOR_H_
#define CLIENTINTERCEPTOR_H_

#include <string.h>
#include <CORBA.h>

#include <openbus/mico/common/CredentialManager.h>

using namespace PortableInterceptor ;

namespace openbus {
  namespace common {
    class ClientInterceptor : public ClientRequestInterceptor {
      private:
        CredentialManager* credentialManager ;
      public:
        ClientInterceptor( CredentialManager* pcredentialManager ) ;
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
}

#endif
