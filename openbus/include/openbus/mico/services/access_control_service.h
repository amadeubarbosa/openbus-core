/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <CORBA.h>
#include <mico/throw.h>

#ifndef __ACCESS_CONTROL_SERVICE_H__
#define __ACCESS_CONTROL_SERVICE_H__






namespace openbusidl
{
namespace acs
{

class ICredentialObserver;
typedef ICredentialObserver *ICredentialObserver_ptr;
typedef ICredentialObserver_ptr ICredentialObserverRef;
typedef ObjVar< ICredentialObserver > ICredentialObserver_var;
typedef ObjOut< ICredentialObserver > ICredentialObserver_out;

class ILeaseProvider;
typedef ILeaseProvider *ILeaseProvider_ptr;
typedef ILeaseProvider_ptr ILeaseProviderRef;
typedef ObjVar< ILeaseProvider > ILeaseProvider_var;
typedef ObjOut< ILeaseProvider > ILeaseProvider_out;

class IAccessControlService;
typedef IAccessControlService *IAccessControlService_ptr;
typedef IAccessControlService_ptr IAccessControlServiceRef;
typedef ObjVar< IAccessControlService > IAccessControlService_var;
typedef ObjOut< IAccessControlService > IAccessControlService_out;

}
}



#include "core.h"
#include "registry_service.h"
#include "scs.h"



namespace openbusidl
{
namespace acs
{

typedef char* CredentialIdentifier;
typedef CORBA::String_var CredentialIdentifier_var;
typedef CORBA::String_out CredentialIdentifier_out;

extern CORBA::TypeCodeConst _tc_CredentialIdentifier;

typedef StringSequenceTmpl<CORBA::String_var> CredentialIdentifierList;
typedef TSeqVar< StringSequenceTmpl<CORBA::String_var> > CredentialIdentifierList_var;
typedef TSeqOut< StringSequenceTmpl<CORBA::String_var> > CredentialIdentifierList_out;

extern CORBA::TypeCodeConst _tc_CredentialIdentifierList;

typedef char* CredentialObserverIdentifier;
typedef CORBA::String_var CredentialObserverIdentifier_var;
typedef CORBA::String_out CredentialObserverIdentifier_out;

extern CORBA::TypeCodeConst _tc_CredentialObserverIdentifier;

struct Credential;
typedef TVarVar< Credential > Credential_var;
typedef TVarOut< Credential > Credential_out;


struct Credential {
  #ifdef HAVE_TYPEDEF_OVERLOAD
  typedef Credential_var _var_type;
  #endif
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  Credential();
  ~Credential();
  Credential( const Credential& s );
  Credential& operator=( const Credential& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS

  CredentialIdentifier_var identifier;
  CORBA::String_var entityName;
};

extern CORBA::TypeCodeConst _tc_Credential;


/*
 * Base class and common definitions for interface ICredentialObserver
 */

class ICredentialObserver : 
  virtual public CORBA::Object
{
  public:
    virtual ~ICredentialObserver();

    #ifdef HAVE_TYPEDEF_OVERLOAD
    typedef ICredentialObserver_ptr _ptr_type;
    typedef ICredentialObserver_var _var_type;
    #endif

    static ICredentialObserver_ptr _narrow( CORBA::Object_ptr obj );
    static ICredentialObserver_ptr _narrow( CORBA::AbstractBase_ptr obj );
    static ICredentialObserver_ptr _duplicate( ICredentialObserver_ptr _obj )
    {
      CORBA::Object::_duplicate (_obj);
      return _obj;
    }

    static ICredentialObserver_ptr _nil()
    {
      return 0;
    }

    virtual void *_narrow_helper( const char *repoid );

    virtual void credentialWasDeleted( const Credential& aCredential ) = 0;

  protected:
    ICredentialObserver() {};
  private:
    ICredentialObserver( const ICredentialObserver& );
    void operator=( const ICredentialObserver& );
};

extern CORBA::TypeCodeConst _tc_ICredentialObserver;

// Stub for interface ICredentialObserver
class ICredentialObserver_stub:
  virtual public ICredentialObserver
{
  public:
    virtual ~ICredentialObserver_stub();
    void credentialWasDeleted( const Credential& aCredential );

  private:
    void operator=( const ICredentialObserver_stub& );
};

typedef CORBA::Long Lease;
typedef Lease& Lease_out;
extern CORBA::TypeCodeConst _tc_Lease;


/*
 * Base class and common definitions for interface ILeaseProvider
 */

class ILeaseProvider : 
  virtual public CORBA::Object
{
  public:
    virtual ~ILeaseProvider();

    #ifdef HAVE_TYPEDEF_OVERLOAD
    typedef ILeaseProvider_ptr _ptr_type;
    typedef ILeaseProvider_var _var_type;
    #endif

    static ILeaseProvider_ptr _narrow( CORBA::Object_ptr obj );
    static ILeaseProvider_ptr _narrow( CORBA::AbstractBase_ptr obj );
    static ILeaseProvider_ptr _duplicate( ILeaseProvider_ptr _obj )
    {
      CORBA::Object::_duplicate (_obj);
      return _obj;
    }

    static ILeaseProvider_ptr _nil()
    {
      return 0;
    }

    virtual void *_narrow_helper( const char *repoid );

    virtual CORBA::Boolean renewLease( const Credential& aCredential, Lease_out aLease ) = 0;

  protected:
    ILeaseProvider() {};
  private:
    ILeaseProvider( const ILeaseProvider& );
    void operator=( const ILeaseProvider& );
};

extern CORBA::TypeCodeConst _tc_ILeaseProvider;

// Stub for interface ILeaseProvider
class ILeaseProvider_stub:
  virtual public ILeaseProvider
{
  public:
    virtual ~ILeaseProvider_stub();
    CORBA::Boolean renewLease( const Credential& aCredential, Lease_out aLease );

  private:
    void operator=( const ILeaseProvider_stub& );
};


/*
 * Base class and common definitions for interface IAccessControlService
 */

class IAccessControlService : 
  virtual public ::scs::core::IComponent,
  virtual public ::openbusidl::acs::ILeaseProvider
{
  public:
    virtual ~IAccessControlService();

    #ifdef HAVE_TYPEDEF_OVERLOAD
    typedef IAccessControlService_ptr _ptr_type;
    typedef IAccessControlService_var _var_type;
    #endif

    static IAccessControlService_ptr _narrow( CORBA::Object_ptr obj );
    static IAccessControlService_ptr _narrow( CORBA::AbstractBase_ptr obj );
    static IAccessControlService_ptr _duplicate( IAccessControlService_ptr _obj )
    {
      CORBA::Object::_duplicate (_obj);
      return _obj;
    }

    static IAccessControlService_ptr _nil()
    {
      return 0;
    }

    virtual void *_narrow_helper( const char *repoid );

    virtual CORBA::Boolean loginByPassword( const char* name, const char* password, Credential_out aCredential, Lease_out aLease ) = 0;
    virtual CORBA::Boolean loginByCertificate( const char* name, const OctetSeq& answer, Credential_out aCredential, Lease_out aLease ) = 0;
    virtual OctetSeq* getChallenge( const char* name ) = 0;
    virtual CORBA::Boolean logout( const Credential& aCredential ) = 0;
    virtual CORBA::Boolean isValid( const Credential& aCredential ) = 0;
    virtual CORBA::Boolean setRegistryService( rs::IRegistryService_ptr registryServiceComponent ) = 0;
    virtual rs::IRegistryService_ptr getRegistryService() = 0;
    virtual char* addObserver( ICredentialObserver_ptr observer, const CredentialIdentifierList& someCredentialIdentifiers ) = 0;
    virtual CORBA::Boolean removeObserver( const char* identifier ) = 0;
    virtual CORBA::Boolean addCredentialToObserver( const char* observerIdentifier, const char* aCredentialIdentifier ) = 0;
    virtual CORBA::Boolean removeCredentialFromObserver( const char* observerIdentifier, const char* aCredentialIdentifier ) = 0;

  protected:
    IAccessControlService() {};
  private:
    IAccessControlService( const IAccessControlService& );
    void operator=( const IAccessControlService& );
};

extern CORBA::TypeCodeConst _tc_IAccessControlService;

// Stub for interface IAccessControlService
class IAccessControlService_stub:
  virtual public IAccessControlService,
  virtual public ::scs::core::IComponent_stub,
  virtual public ::openbusidl::acs::ILeaseProvider_stub
{
  public:
    virtual ~IAccessControlService_stub();
    CORBA::Boolean loginByPassword( const char* name, const char* password, Credential_out aCredential, Lease_out aLease );
    CORBA::Boolean loginByCertificate( const char* name, const OctetSeq& answer, Credential_out aCredential, Lease_out aLease );
    OctetSeq* getChallenge( const char* name );
    CORBA::Boolean logout( const Credential& aCredential );
    CORBA::Boolean isValid( const Credential& aCredential );
    CORBA::Boolean setRegistryService( rs::IRegistryService_ptr registryServiceComponent );
    rs::IRegistryService_ptr getRegistryService();
    char* addObserver( ICredentialObserver_ptr observer, const CredentialIdentifierList& someCredentialIdentifiers );
    CORBA::Boolean removeObserver( const char* identifier );
    CORBA::Boolean addCredentialToObserver( const char* observerIdentifier, const char* aCredentialIdentifier );
    CORBA::Boolean removeCredentialFromObserver( const char* observerIdentifier, const char* aCredentialIdentifier );

  private:
    void operator=( const IAccessControlService_stub& );
};

}
}


#ifndef MICO_CONF_NO_POA

#endif // MICO_CONF_NO_POA

void operator<<=( CORBA::Any &_a, const ::openbusidl::acs::Credential &_s );
void operator<<=( CORBA::Any &_a, ::openbusidl::acs::Credential *_s );
CORBA::Boolean operator>>=( const CORBA::Any &_a, ::openbusidl::acs::Credential &_s );
CORBA::Boolean operator>>=( const CORBA::Any &_a, const ::openbusidl::acs::Credential *&_s );

extern CORBA::StaticTypeInfo *_marshaller_openbusidl_acs_Credential;

void operator<<=( CORBA::Any &a, const openbusidl::acs::ICredentialObserver_ptr obj );
void operator<<=( CORBA::Any &a, openbusidl::acs::ICredentialObserver_ptr* obj_ptr );
CORBA::Boolean operator>>=( const CORBA::Any &a, openbusidl::acs::ICredentialObserver_ptr &obj );

extern CORBA::StaticTypeInfo *_marshaller_openbusidl_acs_ICredentialObserver;

void operator<<=( CORBA::Any &a, const openbusidl::acs::ILeaseProvider_ptr obj );
void operator<<=( CORBA::Any &a, openbusidl::acs::ILeaseProvider_ptr* obj_ptr );
CORBA::Boolean operator>>=( const CORBA::Any &a, openbusidl::acs::ILeaseProvider_ptr &obj );

extern CORBA::StaticTypeInfo *_marshaller_openbusidl_acs_ILeaseProvider;

void operator<<=( CORBA::Any &a, const openbusidl::acs::IAccessControlService_ptr obj );
void operator<<=( CORBA::Any &a, openbusidl::acs::IAccessControlService_ptr* obj_ptr );
CORBA::Boolean operator>>=( const CORBA::Any &a, openbusidl::acs::IAccessControlService_ptr &obj );

extern CORBA::StaticTypeInfo *_marshaller_openbusidl_acs_IAccessControlService;

#endif
