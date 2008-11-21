/*
** openbus.h
*/

#ifndef OPENBUS_H_
#define OPENBUS_H_

#include "services/AccessControlService.h"

#include "stubs/access_control_service.hh"
#include "openbus/common/CredentialManager.h"
#include "openbus/common/ORBInitializerImpl.h"
#include "openbus/common/ServerInterceptor.h"
#include <scs/core/ComponentBuilder.h>

#include <omg/orb.hh>
#include <it_ts/thread.h>

using namespace openbusidl::acs;
IT_USING_NAMESPACE_STD

namespace openbus {
  class Openbus {
    private:
      static Openbus* instance;
      static common::CredentialManager* credentialManager;
      static common::ORBInitializerImpl* ini;
      static CORBA::ORB* orb;
      static PortableServer::POA* poa;
      static scs::core::ComponentBuilder* componentBuilder;
      static PortableServer::POAManager_var poa_manager;
      openbus::services::AccessControlService* accessControlService;
      openbus::services::RegistryService* registryService;
      Lease lease;
      Credential* credential;
      unsigned long timeRenewing;
      IT_Thread renewLeaseIT_Thread;
      Openbus();
      class RenewLeaseThread : public IT_ThreadBody {
        private:
          Openbus* bus;
        public:
          RenewLeaseThread(Openbus* _bus);
          void* run();
      };
    public:
      ~Openbus();
      static Openbus* getInstance();
      void run();
      void init(int argc, char** argv);
      void init(int argc, char** argv, CORBA::ORB_ptr _orb, PortableServer::POA* _poa);
      scs::core::ComponentBuilder* getComponentBuilder();
      common::ServerInterceptor* getServerInterceptor();
      common::CredentialManager* getCredentialManager();
      openbus::services::AccessControlService* getAccessControlService();
      Credential* getCredential();
      Lease getLease();
      openbus::services::RegistryService* connect(const char* host, unsigned short port, const char* user, \
            const char* password);
      bool logout();
  };
}

#endif
