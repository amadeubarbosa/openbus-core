/*
* common/ServerInterceptor.h
*/

#ifndef SERVER_INTERCEPTOR_H_
#define SERVER_INTERCEPTOR_H_

namespace openbus {
  namespace common {
    class ServerInterceptor;
  }
}

#include "../openbus.h"

namespace openbus {
  namespace common {

    class ServerInterceptor {
      private:
        Openbus* openbus;
        static Lua_State* LuaVM;
        Long contextID;
        String credentialType;
        CredentialManager* credentialManager;
      public:
        ServerInterceptor ();
        ~ServerInterceptor();
        services::Credential* getCredential();
    };

  }
}

#endif
