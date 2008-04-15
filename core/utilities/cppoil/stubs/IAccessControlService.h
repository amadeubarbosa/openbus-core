/*
* stubs/IAccessControlService.h
*/

#ifndef IACCESS_CONTROL_SERVICE_H_
#define IACCESS_CONTROL_SERVICE_H_

#include "../openbus.h"

namespace openbus {
  namespace services {

    typedef luaidl::cpp::sequence<char> OctetSeq ;
    typedef Identifier CredentialIdentifier ;
    typedef luaidl::cpp::sequence<const char> CredentialIdentifierList ;
    typedef Identifier CredentialObserverIdentifier ;

    struct Credential {
      String identifier ;
      String entityName ;
    } ;

    typedef Long Lease ;

    class ILeaseProvider {
      public:
        virtual ~ILeaseProvider() {} ;
        virtual bool renewLease ( Credential* aCredential, Lease* aLease ) = 0 ;
    } ;

    class ICredentialObserver {
        void* ptr_luaimpl ;
        static int _credentialWasDeleted_bind ( Lua_State* L ) ;
      public:
        ICredentialObserver () ;
        virtual ~ICredentialObserver () ;
        virtual void credentialWasDeleted ( Credential* aCredential ) {} ;
        friend class openbus::Openbus ;
    } ;

    class IAccessControlService :public ILeaseProvider {
      private:
        IAccessControlService( String reference, String interface ) ;
        IRegistryService* registryService ;
      public:
        ~IAccessControlService( void ) ;
        bool renewLease ( Credential* aCredential, Lease* aLease ) ;
        bool loginByPassword ( String name, String password, Credential* aCredential, Lease* aLease ) ;
        bool loginByCertificate ( String name, const char* answer, \
                Credential* aCredential, Lease* aLease ) ;
      /* !!! atualmente o valor de retorno eh somente uma referencia para uma Lua string */
        const char* getChallenge ( String name ) ;
        bool logout ( Credential* aCredential ) ;
        bool isValid ( Credential* aCredential ) ;
        IRegistryService* getRegistryService() ;
        CredentialObserverIdentifier addObserver( ICredentialObserver* observer, CredentialIdentifierList* \
              someCredentialIdentifiers ) ;
        bool removeObserver( CredentialObserverIdentifier identifier ) ;
        bool addCredentialToObserver ( CredentialObserverIdentifier observerIdentifier, \
              CredentialIdentifier CredentialIdentifier ) ;
        bool removeCredentialFromObserver ( CredentialObserverIdentifier observerIdentifier, \
              CredentialIdentifier CredentialIdentifier) ;
      friend class openbus::Openbus ;
    } ;
  }
}

#endif
