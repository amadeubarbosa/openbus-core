/*
* openbus.h
*/

#ifndef OPENBUS_H_
#define OPENBUS_H_

#include "luaidl/cpp/types.h"

typedef struct lua_State Lua_State ;

namespace scs {
  namespace core {
    class IComponent ;
    typedef luaidl::cpp::sequence<IComponent> IComponentSeq ;
  }
}

namespace openbus {
  typedef luaidl::cpp::types::String String ;
  typedef luaidl::cpp::types::Long Long ;

  typedef String UUID;
  typedef UUID Identifier;

  namespace common {
    class CredentialManager ;
    class ClientInterceptor ;
  }

  namespace services {
    struct Credential ;
    struct ServiceOffer ;
    typedef Identifier RegistryIdentifier ;
    class ICredentialObserver ;
    class IAccessControlService ;
    class IRegistryService ;
    class ISession ;
    class ISessionService ;
  }

  class Openbus;
}

#include "scs/core/IComponent.h"
#include "services/IAccessControlService.h"
#include "services/IRegistryService.h"
#include "services/ISessionService.h"
#include "common/ClientInterceptor.h"
#include "common/CredentialManager.h"

namespace openbus {

/* sigleton pattern */
  class Openbus {
    private:
      static Openbus* pInstance ;
      void initLuaVM( void ) ;
      Openbus( void ) ;
      Openbus( const Openbus& ) ;
      static Lua_State* LuaVM ;
    public:
      static Lua_State* getLuaVM( void ) ;
      static Openbus* getInstance( void ) ;
      void setclientinterceptor( common::ClientInterceptor* clientInterceptor ) ;
      services::IAccessControlService* getACS( String reference, String interface ) ;
      services::IRegistryService* getRGS( String reference, String interface ) ;
      common::CredentialManager* createCredentialManager( void ) ;
      friend class scs::core::IComponent ;
      friend class services::ICredentialObserver ;
      friend class services::IAccessControlService ;
      friend class services::IRegistryService ;
      friend class services::ISession ;
      friend class services::ISessionService ;
      friend class common::CredentialManager ;
      friend class common::ClientInterceptor ;
  } ;

}

#endif
