/*
** AccessControlService.h
*/

#ifndef ACCESSCONTROLSERVICE_H_
#define ACCESSCONTROLSERVICE_H_


#include "RegistryService.h"

#include <omg/orb.hh>
#include "../stubs/access_control_service.hh"
#include "../stubs/registry_service.hh"

namespace openbus {
  namespace services {
    class AccessControlService {
      private:
        CORBA::ORB* orb;
        openbusidl::acs::IAccessControlService* iAccessControlService;
      public:
        AccessControlService(const char* host, short unsigned int port, CORBA::ORB* _orb) throw (CORBA::SystemException);
        RegistryService* getRegistryService();
        bool renewLease(openbusidl::acs::Credential credential, openbusidl::acs::Lease lease);
        bool logout(openbusidl::acs::Credential credential);
        openbusidl::acs::IAccessControlService* getStub();
    };
  }
}

#endif
