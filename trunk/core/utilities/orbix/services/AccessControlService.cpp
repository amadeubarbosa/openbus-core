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
      orb = _orb;
      std::stringstream corbalocACS;
      std::stringstream corbalocIC;
      std::stringstream corbalocLP;
      corbalocACS << "corbaloc::" << host << ":" << port << "/ACS";
      corbalocIC << "corbaloc::" << host << ":" << port << "/IC";
      corbalocLP << "corbaloc::" << host << ":" << port << "/LP";
      CORBA::Object_var objACS = orb->string_to_object(corbalocACS.str().c_str());
      CORBA::Object_var objIC = orb->string_to_object(corbalocIC.str().c_str());
      CORBA::Object_var objLP = orb->string_to_object(corbalocLP.str().c_str());
      iComponent = scs::core::IComponent::_narrow(objIC);
      iAccessControlService = openbusidl::acs::IAccessControlService::_narrow(objACS);
      iLeaseProvider = openbusidl::acs::ILeaseProvider::_narrow(objLP);
    }

    RegistryService* AccessControlService::getRegistryService() {
      return new RegistryService(iAccessControlService->getRegistryService());
    }

    bool AccessControlService::renewLease(openbusidl::acs::Credential credential, openbusidl::acs::Lease lease) {
      return iLeaseProvider->renewLease(credential, lease);
    }

    bool AccessControlService::logout(openbusidl::acs::Credential credential) {
      return iAccessControlService->logout(credential);
    }

    openbusidl::acs::IAccessControlService* AccessControlService::getStub() {
      return iAccessControlService;
    }

  }
}
