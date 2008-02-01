/*
* oil/common/ClientInterceptor.h
*/

#ifndef CLIENT_INTERCEPTOR_H_
#define CLIENT_INTERCEPTOR_H_

#include "../openbus.h"

namespace openbus {
  namespace common {

    class ClientInterceptor {
      private:
        Long contextID ;
        String credentialType ;
        CredentialManager* credentialManager ;
      public:
        static int sendrequest( lua_State* L ) ;
        ClientInterceptor ( String configPATH, CredentialManager* pcredentialManager ) ;
        ~ClientInterceptor() ;
        friend class Openbus ;
    } ;

  }
}

#endif
