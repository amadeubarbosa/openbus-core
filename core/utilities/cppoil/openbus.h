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

  namespace common {
    class CredentialManager;
    class ClientInterceptor;
  }

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

#include "stubs/IAccessControlService.h"
#include "stubs/IRegistryService.h"
#include "stubs/ISessionService.h"
#include "common/ClientInterceptor.h"
#include "common/CredentialManager.h"

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
      friend class services::ICredentialObserver;
      friend class services::IAccessControlService;
      friend class services::IRegistryService;
      friend class services::ISession;
      friend class services::ISessionService;
      friend class services::SessionEventSink;
      friend class common::CredentialManager;
  };

}

#endif
