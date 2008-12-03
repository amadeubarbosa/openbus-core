/*
** AccessControlService.cpp
*/

#include "AccessControlService.h"

#include <sstream>

namespace openbus {
  namespace services {
    AccessControlService::AccessControlService(const char* host, short unsigned int port, CORBA::ORB* _orb) \
        throw (CORBA::SystemException)
    {
      std::stringstream corbaloc;
      orb = _orb;
      corbaloc << "corbaloc::" << host << ":" << port << "/ACS";
      CORBA::Object_var obj = orb->string_to_object(corbaloc.str().c_str());
      iAccessControlService = openbusidl::acs::IAccessControlService::_narrow(obj);
    }

    RegistryService* AccessControlService::getRegistryService() {
      return new RegistryService(iAccessControlService->getRegistryService());
    }

    bool AccessControlService::renewLease(openbusidl::acs::Credential credential, openbusidl::acs::Lease lease) {
      return iAccessControlService->renewLease(credential, lease);
    }

    bool AccessControlService::logout(openbusidl::acs::Credential credential) {
      return iAccessControlService->logout(credential);
    }

    openbusidl::acs::IAccessControlService* AccessControlService::getStub() {
      return iAccessControlService;
    }

  }
}
