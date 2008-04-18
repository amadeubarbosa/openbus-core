/*
* common/ClientInterceptor.h
*/

#ifndef CLIENT_INTERCEPTOR_H_
#define CLIENT_INTERCEPTOR_H_

#include "../openbus.h"

namespace openbus {
  namespace common {

    class ClientInterceptor {
      private:
        Openbus* openbus;
        static Lua_State* LuaVM;
        Long contextID;
        String credentialType;
        CredentialManager* credentialManager;
      public:
        static int sendrequest(lua_State* L);
        ClientInterceptor (CredentialManager* pcredentialManager);
        ~ClientInterceptor();
    };

  }
}

#endif
