/*
** common/CredentialManager.h
*/

#ifndef CREDENTIAL_MANAGER_H_
#define CREDENTIAL_MANAGER_H_

#include "../openbus.h"

namespace openbus {
  namespace common {

    class CredentialManager {
      private:
        services::Credential* credentialValue ;

      public:
        CredentialManager() ;
        ~CredentialManager() ;

        void setValue( services::Credential* credential ) ;
        services::Credential* getValue() ;
        bool hasValue() ;
        void invalidate() ;
        friend class Openbus ;
    } ;

  }
}

#endif
