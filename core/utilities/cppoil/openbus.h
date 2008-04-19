/*
** openbus.h
*/

#ifndef OPENBUS_H_
#define OPENBUS_H_

#include "luaidl/cpp/types.h"

#include <scs/core/IComponentOil.h>

typedef struct lua_State Lua_State;

namespace openbus {
  typedef luaidl::cpp::types::String String;
  typedef luaidl::cpp::types::Long Long;

  typedef String UUID;
  typedef UUID Identifier;

  namespace services {
    struct Credential;
    struct ServiceOffer;
    typedef Identifier RegistryIdentifier;
    class ICredentialObserver;
    class IAccessControlService;
    class IRegistryService;
    class ISession;
    class ISessionService;
    class SessionEventSink;
  }

  class Openbus;
}

#include "common/CredentialManager.h"
#include "common/ClientInterceptor.h"
#include "stubs/IAccessControlService.h"
#include "stubs/IRegistryService.h"
#include "stubs/ISessionService.h"

namespace openbus {

/* sigleton pattern */
  class Openbus {
    private:
      static Openbus* instance;
      static Lua_State* LuaVM;
      void initLuaVM();
      Openbus();
      Openbus(const Openbus&);
    public:
      ~Openbus();
      static Openbus* getInstance();
      Lua_State* getLuaVM();
      void setClientInterceptor(common::ClientInterceptor* clientInterceptor);
      services::IAccessControlService* getACS(String reference, String interface);
  };

}

#endif
