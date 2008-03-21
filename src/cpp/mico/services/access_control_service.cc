/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <openbus/mico/services/access_control_service.h>


using namespace std;

//--------------------------------------------------------
//  Implementation of stubs
//--------------------------------------------------------
namespace openbusidl
{
namespace acs
{
CORBA::TypeCodeConst _tc_CredentialIdentifier;
}
}

namespace openbusidl
{
namespace acs
{
CORBA::TypeCodeConst _tc_CredentialIdentifierList;
}
}

namespace openbusidl
{
namespace acs
{
CORBA::TypeCodeConst _tc_CredentialObserverIdentifier;
}
}

namespace openbusidl
{
namespace acs
{
CORBA::TypeCodeConst _tc_Credential;
}
}

#ifdef HAVE_EXPLICIT_STRUCT_OPS
openbusidl::acs::Credential::Credential()
{
}

openbusidl::acs::Credential::Credential( const Credential& _s )
{
  identifier = ((Credential&)_s).identifier;
  entityName = ((Credential&)_s).entityName;
}

openbusidl::acs::Credential::~Credential()
{
}

openbusidl::acs::Credential&
openbusidl::acs::Credential::operator=( const Credential& _s )
{
  identifier = ((Credential&)_s).identifier;
  entityName = ((Credential&)_s).entityName;
  return *this;
}
#endif

class _Marshaller_openbusidl_acs_Credential : public ::CORBA::StaticTypeInfo {
    typedef openbusidl::acs::Credential _MICO_T;
  public:
    ~_Marshaller_openbusidl_acs_Credential();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
    ::CORBA::TypeCode_ptr typecode ();
};


_Marshaller_openbusidl_acs_Credential::~_Marshaller_openbusidl_acs_Credential()
{
}

::CORBA::StaticValueType _Marshaller_openbusidl_acs_Credential::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_openbusidl_acs_Credential::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_openbusidl_acs_Credential::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_openbusidl_acs_Credential::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  return
    dc.struct_begin() &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->identifier._for_demarshal() ) &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->entityName._for_demarshal() ) &&
    dc.struct_end();
}

void _Marshaller_openbusidl_acs_Credential::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.struct_begin();
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->identifier.inout() );
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->entityName.inout() );
  ec.struct_end();
}

::CORBA::TypeCode_ptr _Marshaller_openbusidl_acs_Credential::typecode()
{
  return openbusidl::acs::_tc_Credential;
}

::CORBA::StaticTypeInfo *_marshaller_openbusidl_acs_Credential;

void operator<<=( CORBA::Any &_a, const openbusidl::acs::Credential &_s )
{
  CORBA::StaticAny _sa (_marshaller_openbusidl_acs_Credential, &_s);
  _a.from_static_any (_sa);
}

void operator<<=( CORBA::Any &_a, openbusidl::acs::Credential *_s )
{
  _a <<= *_s;
  delete _s;
}

CORBA::Boolean operator>>=( const CORBA::Any &_a, openbusidl::acs::Credential &_s )
{
  CORBA::StaticAny _sa (_marshaller_openbusidl_acs_Credential, &_s);
  return _a.to_static_any (_sa);
}

CORBA::Boolean operator>>=( const CORBA::Any &_a, const openbusidl::acs::Credential *&_s )
{
  return _a.to_static_any (_marshaller_openbusidl_acs_Credential, (void *&)_s);
}


/*
 * Base interface for class ICredentialObserver
 */

openbusidl::acs::ICredentialObserver::~ICredentialObserver()
{
}

void *
openbusidl::acs::ICredentialObserver::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:openbusidl/acs/ICredentialObserver:1.0" ) == 0 )
    return (void *)this;
  return NULL;
}

openbusidl::acs::ICredentialObserver_ptr
openbusidl::acs::ICredentialObserver::_narrow( CORBA::Object_ptr _obj )
{
  openbusidl::acs::ICredentialObserver_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:openbusidl/acs/ICredentialObserver:1.0" )))
      return _duplicate( (openbusidl::acs::ICredentialObserver_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:openbusidl/acs/ICredentialObserver:1.0") || _obj->_is_a_remote ("IDL:openbusidl/acs/ICredentialObserver:1.0")) {
      _o = new openbusidl::acs::ICredentialObserver_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

openbusidl::acs::ICredentialObserver_ptr
openbusidl::acs::ICredentialObserver::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

namespace openbusidl
{
namespace acs
{
CORBA::TypeCodeConst _tc_ICredentialObserver;
}
}
class _Marshaller_openbusidl_acs_ICredentialObserver : public ::CORBA::StaticTypeInfo {
    typedef openbusidl::acs::ICredentialObserver_ptr _MICO_T;
  public:
    ~_Marshaller_openbusidl_acs_ICredentialObserver();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
    ::CORBA::TypeCode_ptr typecode ();
};


_Marshaller_openbusidl_acs_ICredentialObserver::~_Marshaller_openbusidl_acs_ICredentialObserver()
{
}

::CORBA::StaticValueType _Marshaller_openbusidl_acs_ICredentialObserver::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_openbusidl_acs_ICredentialObserver::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::openbusidl::acs::ICredentialObserver::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_openbusidl_acs_ICredentialObserver::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_openbusidl_acs_ICredentialObserver::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_openbusidl_acs_ICredentialObserver::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::openbusidl::acs::ICredentialObserver::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_openbusidl_acs_ICredentialObserver::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::TypeCode_ptr _Marshaller_openbusidl_acs_ICredentialObserver::typecode()
{
  return openbusidl::acs::_tc_ICredentialObserver;
}

::CORBA::StaticTypeInfo *_marshaller_openbusidl_acs_ICredentialObserver;

void
operator<<=( CORBA::Any &_a, const openbusidl::acs::ICredentialObserver_ptr _obj )
{
  CORBA::StaticAny _sa (_marshaller_openbusidl_acs_ICredentialObserver, &_obj);
  _a.from_static_any (_sa);
}

void
operator<<=( CORBA::Any &_a, openbusidl::acs::ICredentialObserver_ptr* _obj_ptr )
{
  CORBA::StaticAny _sa (_marshaller_openbusidl_acs_ICredentialObserver, _obj_ptr);
  _a.from_static_any (_sa);
  CORBA::release (*_obj_ptr);
}

CORBA::Boolean
operator>>=( const CORBA::Any &_a, openbusidl::acs::ICredentialObserver_ptr &_obj )
{
  openbusidl::acs::ICredentialObserver_ptr *p;
  if (_a.to_static_any (_marshaller_openbusidl_acs_ICredentialObserver, (void *&)p)) {
    _obj = *p;
    return TRUE;
  }
  return FALSE;
}


/*
 * Stub interface for class ICredentialObserver
 */

openbusidl::acs::ICredentialObserver_stub::~ICredentialObserver_stub()
{
}

void openbusidl::acs::ICredentialObserver_stub::credentialWasDeleted( const openbusidl::acs::Credential& _par_aCredential )
{
  CORBA::StaticAny _sa_aCredential( _marshaller_openbusidl_acs_Credential, &_par_aCredential );
  CORBA::StaticRequest __req( this, "credentialWasDeleted" );
  __req.add_in_arg( &_sa_aCredential );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
}


namespace openbusidl
{
namespace acs
{
CORBA::TypeCodeConst _tc_Lease;
}
}


/*
 * Base interface for class ILeaseProvider
 */

openbusidl::acs::ILeaseProvider::~ILeaseProvider()
{
}

void *
openbusidl::acs::ILeaseProvider::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:openbusidl/acs/ILeaseProvider:1.0" ) == 0 )
    return (void *)this;
  return NULL;
}

openbusidl::acs::ILeaseProvider_ptr
openbusidl::acs::ILeaseProvider::_narrow( CORBA::Object_ptr _obj )
{
  openbusidl::acs::ILeaseProvider_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:openbusidl/acs/ILeaseProvider:1.0" )))
      return _duplicate( (openbusidl::acs::ILeaseProvider_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:openbusidl/acs/ILeaseProvider:1.0") || _obj->_is_a_remote ("IDL:openbusidl/acs/ILeaseProvider:1.0")) {
      _o = new openbusidl::acs::ILeaseProvider_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

openbusidl::acs::ILeaseProvider_ptr
openbusidl::acs::ILeaseProvider::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

namespace openbusidl
{
namespace acs
{
CORBA::TypeCodeConst _tc_ILeaseProvider;
}
}
class _Marshaller_openbusidl_acs_ILeaseProvider : public ::CORBA::StaticTypeInfo {
    typedef openbusidl::acs::ILeaseProvider_ptr _MICO_T;
  public:
    ~_Marshaller_openbusidl_acs_ILeaseProvider();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
    ::CORBA::TypeCode_ptr typecode ();
};


_Marshaller_openbusidl_acs_ILeaseProvider::~_Marshaller_openbusidl_acs_ILeaseProvider()
{
}

::CORBA::StaticValueType _Marshaller_openbusidl_acs_ILeaseProvider::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_openbusidl_acs_ILeaseProvider::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::openbusidl::acs::ILeaseProvider::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_openbusidl_acs_ILeaseProvider::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_openbusidl_acs_ILeaseProvider::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_openbusidl_acs_ILeaseProvider::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::openbusidl::acs::ILeaseProvider::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_openbusidl_acs_ILeaseProvider::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::TypeCode_ptr _Marshaller_openbusidl_acs_ILeaseProvider::typecode()
{
  return openbusidl::acs::_tc_ILeaseProvider;
}

::CORBA::StaticTypeInfo *_marshaller_openbusidl_acs_ILeaseProvider;

void
operator<<=( CORBA::Any &_a, const openbusidl::acs::ILeaseProvider_ptr _obj )
{
  CORBA::StaticAny _sa (_marshaller_openbusidl_acs_ILeaseProvider, &_obj);
  _a.from_static_any (_sa);
}

void
operator<<=( CORBA::Any &_a, openbusidl::acs::ILeaseProvider_ptr* _obj_ptr )
{
  CORBA::StaticAny _sa (_marshaller_openbusidl_acs_ILeaseProvider, _obj_ptr);
  _a.from_static_any (_sa);
  CORBA::release (*_obj_ptr);
}

CORBA::Boolean
operator>>=( const CORBA::Any &_a, openbusidl::acs::ILeaseProvider_ptr &_obj )
{
  openbusidl::acs::ILeaseProvider_ptr *p;
  if (_a.to_static_any (_marshaller_openbusidl_acs_ILeaseProvider, (void *&)p)) {
    _obj = *p;
    return TRUE;
  }
  return FALSE;
}


/*
 * Stub interface for class ILeaseProvider
 */

openbusidl::acs::ILeaseProvider_stub::~ILeaseProvider_stub()
{
}

CORBA::Boolean openbusidl::acs::ILeaseProvider_stub::renewLease( const openbusidl::acs::Credential& _par_aCredential, openbusidl::acs::Lease_out _par_aLease )
{
  CORBA::StaticAny _sa_aCredential( _marshaller_openbusidl_acs_Credential, &_par_aCredential );
  CORBA::StaticAny _sa_aLease( CORBA::_stc_long, &_par_aLease );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "renewLease" );
  __req.add_in_arg( &_sa_aCredential );
  __req.add_out_arg( &_sa_aLease );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}



/*
 * Base interface for class IAccessControlService
 */

openbusidl::acs::IAccessControlService::~IAccessControlService()
{
}

void *
openbusidl::acs::IAccessControlService::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:openbusidl/acs/IAccessControlService:1.0" ) == 0 )
    return (void *)this;
  {
    void *_p;
    if ((_p = scs::core::IComponent::_narrow_helper( _repoid )))
      return _p;
  }
  {
    void *_p;
    if ((_p = openbusidl::acs::ILeaseProvider::_narrow_helper( _repoid )))
      return _p;
  }
  return NULL;
}

openbusidl::acs::IAccessControlService_ptr
openbusidl::acs::IAccessControlService::_narrow( CORBA::Object_ptr _obj )
{
  openbusidl::acs::IAccessControlService_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:openbusidl/acs/IAccessControlService:1.0" )))
      return _duplicate( (openbusidl::acs::IAccessControlService_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:openbusidl/acs/IAccessControlService:1.0") || _obj->_is_a_remote ("IDL:openbusidl/acs/IAccessControlService:1.0")) {
      _o = new openbusidl::acs::IAccessControlService_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

openbusidl::acs::IAccessControlService_ptr
openbusidl::acs::IAccessControlService::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

namespace openbusidl
{
namespace acs
{
CORBA::TypeCodeConst _tc_IAccessControlService;
}
}
class _Marshaller_openbusidl_acs_IAccessControlService : public ::CORBA::StaticTypeInfo {
    typedef openbusidl::acs::IAccessControlService_ptr _MICO_T;
  public:
    ~_Marshaller_openbusidl_acs_IAccessControlService();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
    ::CORBA::TypeCode_ptr typecode ();
};


_Marshaller_openbusidl_acs_IAccessControlService::~_Marshaller_openbusidl_acs_IAccessControlService()
{
}

::CORBA::StaticValueType _Marshaller_openbusidl_acs_IAccessControlService::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_openbusidl_acs_IAccessControlService::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::openbusidl::acs::IAccessControlService::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_openbusidl_acs_IAccessControlService::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_openbusidl_acs_IAccessControlService::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_openbusidl_acs_IAccessControlService::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::openbusidl::acs::IAccessControlService::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_openbusidl_acs_IAccessControlService::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::TypeCode_ptr _Marshaller_openbusidl_acs_IAccessControlService::typecode()
{
  return openbusidl::acs::_tc_IAccessControlService;
}

::CORBA::StaticTypeInfo *_marshaller_openbusidl_acs_IAccessControlService;

void
operator<<=( CORBA::Any &_a, const openbusidl::acs::IAccessControlService_ptr _obj )
{
  CORBA::StaticAny _sa (_marshaller_openbusidl_acs_IAccessControlService, &_obj);
  _a.from_static_any (_sa);
}

void
operator<<=( CORBA::Any &_a, openbusidl::acs::IAccessControlService_ptr* _obj_ptr )
{
  CORBA::StaticAny _sa (_marshaller_openbusidl_acs_IAccessControlService, _obj_ptr);
  _a.from_static_any (_sa);
  CORBA::release (*_obj_ptr);
}

CORBA::Boolean
operator>>=( const CORBA::Any &_a, openbusidl::acs::IAccessControlService_ptr &_obj )
{
  openbusidl::acs::IAccessControlService_ptr *p;
  if (_a.to_static_any (_marshaller_openbusidl_acs_IAccessControlService, (void *&)p)) {
    _obj = *p;
    return TRUE;
  }
  return FALSE;
}


/*
 * Stub interface for class IAccessControlService
 */

openbusidl::acs::IAccessControlService_stub::~IAccessControlService_stub()
{
}

CORBA::Boolean openbusidl::acs::IAccessControlService_stub::loginByPassword( const char* _par_name, const char* _par_password, openbusidl::acs::Credential_out _par_aCredential, openbusidl::acs::Lease_out _par_aLease )
{
  CORBA::StaticAny _sa_name( CORBA::_stc_string, &_par_name );
  CORBA::StaticAny _sa_password( CORBA::_stc_string, &_par_password );
  CORBA::StaticAny _sa_aCredential( _marshaller_openbusidl_acs_Credential );
  CORBA::StaticAny _sa_aLease( CORBA::_stc_long, &_par_aLease );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "loginByPassword" );
  __req.add_in_arg( &_sa_name );
  __req.add_in_arg( &_sa_password );
  __req.add_out_arg( &_sa_aCredential );
  __req.add_out_arg( &_sa_aLease );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  _par_aCredential = (openbusidl::acs::Credential*) _sa_aCredential._retn();
  return _res;
}


CORBA::Boolean openbusidl::acs::IAccessControlService_stub::loginByCertificate( const char* _par_name, const openbusidl::OctetSeq& _par_answer, openbusidl::acs::Credential_out _par_aCredential, openbusidl::acs::Lease_out _par_aLease )
{
  CORBA::StaticAny _sa_name( CORBA::_stc_string, &_par_name );
  CORBA::StaticAny _sa_answer( CORBA::_stcseq_octet, &_par_answer );
  CORBA::StaticAny _sa_aCredential( _marshaller_openbusidl_acs_Credential );
  CORBA::StaticAny _sa_aLease( CORBA::_stc_long, &_par_aLease );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "loginByCertificate" );
  __req.add_in_arg( &_sa_name );
  __req.add_in_arg( &_sa_answer );
  __req.add_out_arg( &_sa_aCredential );
  __req.add_out_arg( &_sa_aLease );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  _par_aCredential = (openbusidl::acs::Credential*) _sa_aCredential._retn();
  return _res;
}


openbusidl::OctetSeq* openbusidl::acs::IAccessControlService_stub::getChallenge( const char* _par_name )
{
  CORBA::StaticAny _sa_name( CORBA::_stc_string, &_par_name );
  CORBA::StaticAny __res( CORBA::_stcseq_octet );

  CORBA::StaticRequest __req( this, "getChallenge" );
  __req.add_in_arg( &_sa_name );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return (openbusidl::OctetSeq*) __res._retn();
}


CORBA::Boolean openbusidl::acs::IAccessControlService_stub::logout( const openbusidl::acs::Credential& _par_aCredential )
{
  CORBA::StaticAny _sa_aCredential( _marshaller_openbusidl_acs_Credential, &_par_aCredential );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "logout" );
  __req.add_in_arg( &_sa_aCredential );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


CORBA::Boolean openbusidl::acs::IAccessControlService_stub::isValid( const openbusidl::acs::Credential& _par_aCredential )
{
  CORBA::StaticAny _sa_aCredential( _marshaller_openbusidl_acs_Credential, &_par_aCredential );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "isValid" );
  __req.add_in_arg( &_sa_aCredential );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


CORBA::Boolean openbusidl::acs::IAccessControlService_stub::setRegistryService( openbusidl::rs::IRegistryService_ptr _par_registryServiceComponent )
{
  CORBA::StaticAny _sa_registryServiceComponent( _marshaller_openbusidl_rs_IRegistryService, &_par_registryServiceComponent );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "setRegistryService" );
  __req.add_in_arg( &_sa_registryServiceComponent );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


openbusidl::rs::IRegistryService_ptr openbusidl::acs::IAccessControlService_stub::getRegistryService()
{
  openbusidl::rs::IRegistryService_ptr _res = openbusidl::rs::IRegistryService::_nil();
  CORBA::StaticAny __res( _marshaller_openbusidl_rs_IRegistryService, &_res );

  CORBA::StaticRequest __req( this, "getRegistryService" );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


char* openbusidl::acs::IAccessControlService_stub::addObserver( openbusidl::acs::ICredentialObserver_ptr _par_observer, const openbusidl::acs::CredentialIdentifierList& _par_someCredentialIdentifiers )
{
  CORBA::StaticAny _sa_observer( _marshaller_openbusidl_acs_ICredentialObserver, &_par_observer );
  CORBA::StaticAny _sa_someCredentialIdentifiers( CORBA::_stcseq_string, &_par_someCredentialIdentifiers );
  openbusidl::acs::CredentialObserverIdentifier _res = NULL;
  CORBA::StaticAny __res( CORBA::_stc_string, &_res );

  CORBA::StaticRequest __req( this, "addObserver" );
  __req.add_in_arg( &_sa_observer );
  __req.add_in_arg( &_sa_someCredentialIdentifiers );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


CORBA::Boolean openbusidl::acs::IAccessControlService_stub::removeObserver( const char* _par_identifier )
{
  CORBA::StaticAny _sa_identifier( CORBA::_stc_string, &_par_identifier );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "removeObserver" );
  __req.add_in_arg( &_sa_identifier );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


CORBA::Boolean openbusidl::acs::IAccessControlService_stub::addCredentialToObserver( const char* _par_observerIdentifier, const char* _par_aCredentialIdentifier )
{
  CORBA::StaticAny _sa_observerIdentifier( CORBA::_stc_string, &_par_observerIdentifier );
  CORBA::StaticAny _sa_aCredentialIdentifier( CORBA::_stc_string, &_par_aCredentialIdentifier );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "addCredentialToObserver" );
  __req.add_in_arg( &_sa_observerIdentifier );
  __req.add_in_arg( &_sa_aCredentialIdentifier );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


CORBA::Boolean openbusidl::acs::IAccessControlService_stub::removeCredentialFromObserver( const char* _par_observerIdentifier, const char* _par_aCredentialIdentifier )
{
  CORBA::StaticAny _sa_observerIdentifier( CORBA::_stc_string, &_par_observerIdentifier );
  CORBA::StaticAny _sa_aCredentialIdentifier( CORBA::_stc_string, &_par_aCredentialIdentifier );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "removeCredentialFromObserver" );
  __req.add_in_arg( &_sa_observerIdentifier );
  __req.add_in_arg( &_sa_aCredentialIdentifier );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


struct __tc_init_ACCESS_CONTROL_SERVICE {
  __tc_init_ACCESS_CONTROL_SERVICE()
  {
    openbusidl::acs::_tc_CredentialIdentifier = 
    "0100000015000000cc000000010000002c00000049444c3a6f70656e6275"
    "7369646c2f6163732f43726564656e7469616c4964656e7469666965723a"
    "312e30001500000043726564656e7469616c4964656e7469666965720000"
    "00001500000074000000010000001e00000049444c3a6f70656e62757369"
    "646c2f4964656e7469666965723a312e300000000b0000004964656e7469"
    "6669657200001500000034000000010000001800000049444c3a6f70656e"
    "62757369646c2f555549443a312e30000500000055554944000000001200"
    "000000000000";
    openbusidl::acs::_tc_CredentialIdentifierList = 
    "01000000150000003c010000010000003000000049444c3a6f70656e6275"
    "7369646c2f6163732f43726564656e7469616c4964656e7469666965724c"
    "6973743a312e30001900000043726564656e7469616c4964656e74696669"
    "65724c6973740000000013000000dc0000000100000015000000cc000000"
    "010000002c00000049444c3a6f70656e62757369646c2f6163732f437265"
    "64656e7469616c4964656e7469666965723a312e30001500000043726564"
    "656e7469616c4964656e7469666965720000000015000000740000000100"
    "00001e00000049444c3a6f70656e62757369646c2f4964656e7469666965"
    "723a312e300000000b0000004964656e7469666965720000150000003400"
    "0000010000001800000049444c3a6f70656e62757369646c2f555549443a"
    "312e3000050000005555494400000000120000000000000000000000";
    openbusidl::acs::_tc_CredentialObserverIdentifier = 
    "0100000015000000dc000000010000003400000049444c3a6f70656e6275"
    "7369646c2f6163732f43726564656e7469616c4f62736572766572496465"
    "6e7469666965723a312e30001d00000043726564656e7469616c4f627365"
    "727665724964656e74696669657200000000150000007400000001000000"
    "1e00000049444c3a6f70656e62757369646c2f4964656e7469666965723a"
    "312e300000000b0000004964656e74696669657200001500000034000000"
    "010000001800000049444c3a6f70656e62757369646c2f555549443a312e"
    "30000500000055554944000000001200000000000000";
    openbusidl::acs::_tc_Credential = 
    "010000000f0000003c010000010000002200000049444c3a6f70656e6275"
    "7369646c2f6163732f43726564656e7469616c3a312e300000000b000000"
    "43726564656e7469616c0000020000000b0000006964656e746966696572"
    "000015000000cc000000010000002c00000049444c3a6f70656e62757369"
    "646c2f6163732f43726564656e7469616c4964656e7469666965723a312e"
    "30001500000043726564656e7469616c4964656e74696669657200000000"
    "1500000074000000010000001e00000049444c3a6f70656e62757369646c"
    "2f4964656e7469666965723a312e300000000b0000004964656e74696669"
    "657200001500000034000000010000001800000049444c3a6f70656e6275"
    "7369646c2f555549443a312e300005000000555549440000000012000000"
    "000000000b000000656e746974794e616d6500001200000000000000";
    _marshaller_openbusidl_acs_Credential = new _Marshaller_openbusidl_acs_Credential;
    openbusidl::acs::_tc_ICredentialObserver = 
    "010000000e0000004c000000010000002b00000049444c3a6f70656e6275"
    "7369646c2f6163732f4943726564656e7469616c4f627365727665723a31"
    "2e300000140000004943726564656e7469616c4f6273657276657200";
    _marshaller_openbusidl_acs_ICredentialObserver = new _Marshaller_openbusidl_acs_ICredentialObserver;
    openbusidl::acs::_tc_Lease = 
    "010000001500000038000000010000001d00000049444c3a6f70656e6275"
    "7369646c2f6163732f4c656173653a312e3000000000060000004c656173"
    "6500000003000000";
    openbusidl::acs::_tc_ILeaseProvider = 
    "010000000e00000043000000010000002600000049444c3a6f70656e6275"
    "7369646c2f6163732f494c6561736550726f76696465723a312e30000000"
    "0f000000494c6561736550726f766964657200";
    _marshaller_openbusidl_acs_ILeaseProvider = new _Marshaller_openbusidl_acs_ILeaseProvider;
    openbusidl::acs::_tc_IAccessControlService = 
    "010000000e00000052000000010000002d00000049444c3a6f70656e6275"
    "7369646c2f6163732f49416363657373436f6e74726f6c53657276696365"
    "3a312e30000000001600000049416363657373436f6e74726f6c53657276"
    "69636500";
    _marshaller_openbusidl_acs_IAccessControlService = new _Marshaller_openbusidl_acs_IAccessControlService;
  }

  ~__tc_init_ACCESS_CONTROL_SERVICE()
  {
    delete static_cast<_Marshaller_openbusidl_acs_Credential*>(_marshaller_openbusidl_acs_Credential);
    delete static_cast<_Marshaller_openbusidl_acs_ICredentialObserver*>(_marshaller_openbusidl_acs_ICredentialObserver);
    delete static_cast<_Marshaller_openbusidl_acs_ILeaseProvider*>(_marshaller_openbusidl_acs_ILeaseProvider);
    delete static_cast<_Marshaller_openbusidl_acs_IAccessControlService*>(_marshaller_openbusidl_acs_IAccessControlService);
  }
};

static __tc_init_ACCESS_CONTROL_SERVICE __init_ACCESS_CONTROL_SERVICE;

//--------------------------------------------------------
//  Implementation of skeletons
//--------------------------------------------------------
