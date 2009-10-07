/*
* interceptors/CredentialManager.h
*/

#ifndef CREDENTIAL_MANAGER_H_
#define CREDENTIAL_MANAGER_H_

#include "../../stubs/access_control_service.h"

namespace openbus {
  namespace interceptors {
    class CredentialManager {
      private:
        openbusidl::acs::Credential* credentialValue ;

      public:
        CredentialManager() ;
        ~CredentialManager() ;

        void setValue( openbusidl::acs::Credential* credential ) ;
        openbusidl::acs::Credential* getValue() ;
        bool hasValue() ;
        void invalidate() ;
    } ;
  }
}

#endif
