/*
* common/CredentialManager.cpp
*/

#include "CredentialManager.h"

namespace openbus {
  namespace common {
    CredentialManager::CredentialManager() {
    #if VERBOSE
      printf( "\n\n[CredentialManager::CredentialManager() COMECO]\n" ) ;
      printf( "\t[Criando instancia de CredentialManager]\n" ) ;
    #endif
      credentialValue = NULL ;
    #if VERBOSE
      printf( "[CredentialManager::CredentialManager() FIM]\n\n" ) ;
    #endif
    }

    CredentialManager::~CredentialManager() { }

    void CredentialManager::setValue( openbusidl::acs::Credential* credential ) {
      credentialValue = credential ;
    }

    openbusidl::acs::Credential* CredentialManager::getValue() {
      return credentialValue ;
    }

    bool CredentialManager::hasValue() {
      return ( credentialValue != NULL ) ;
    }

    void CredentialManager::invalidate() {
      credentialValue = NULL ;
    }
  }
}
