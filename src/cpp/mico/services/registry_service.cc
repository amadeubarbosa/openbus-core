/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <openbus/mico/services/registry_service.h>


using namespace std;

//--------------------------------------------------------
//  Implementation of stubs
//--------------------------------------------------------

#ifdef HAVE_EXPLICIT_STRUCT_OPS
openbusidl::rs::Property::Property()
{
}

openbusidl::rs::Property::Property( const Property& _s )
{
  name = ((Property&)_s).name;
  value = ((Property&)_s).value;
}

openbusidl::rs::Property::~Property()
{
}

openbusidl::rs::Property&
openbusidl::rs::Property::operator=( const Property& _s )
{
  name = ((Property&)_s).name;
  value = ((Property&)_s).value;
  return *this;
}
#endif

class _Marshaller_openbusidl_rs_Property : public ::CORBA::StaticTypeInfo {
    typedef openbusidl::rs::Property _MICO_T;
  public:
    ~_Marshaller_openbusidl_rs_Property();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_openbusidl_rs_Property::~_Marshaller_openbusidl_rs_Property()
{
}

::CORBA::StaticValueType _Marshaller_openbusidl_rs_Property::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_openbusidl_rs_Property::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_openbusidl_rs_Property::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_openbusidl_rs_Property::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  return
    dc.struct_begin() &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->name._for_demarshal() ) &&
    CORBA::_stcseq_string->demarshal( dc, &((_MICO_T*)v)->value ) &&
    dc.struct_end();
}

void _Marshaller_openbusidl_rs_Property::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.struct_begin();
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->name.inout() );
  CORBA::_stcseq_string->marshal( ec, &((_MICO_T*)v)->value );
  ec.struct_end();
}

::CORBA::StaticTypeInfo *_marshaller_openbusidl_rs_Property;


#ifdef HAVE_EXPLICIT_STRUCT_OPS
openbusidl::rs::ServiceOffer::ServiceOffer()
{
}

openbusidl::rs::ServiceOffer::ServiceOffer( const ServiceOffer& _s )
{
  type = ((ServiceOffer&)_s).type;
  description = ((ServiceOffer&)_s).description;
  properties = ((ServiceOffer&)_s).properties;
  member = ((ServiceOffer&)_s).member;
}

openbusidl::rs::ServiceOffer::~ServiceOffer()
{
}

openbusidl::rs::ServiceOffer&
openbusidl::rs::ServiceOffer::operator=( const ServiceOffer& _s )
{
  type = ((ServiceOffer&)_s).type;
  description = ((ServiceOffer&)_s).description;
  properties = ((ServiceOffer&)_s).properties;
  member = ((ServiceOffer&)_s).member;
  return *this;
}
#endif

class _Marshaller_openbusidl_rs_ServiceOffer : public ::CORBA::StaticTypeInfo {
    typedef openbusidl::rs::ServiceOffer _MICO_T;
  public:
    ~_Marshaller_openbusidl_rs_ServiceOffer();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_openbusidl_rs_ServiceOffer::~_Marshaller_openbusidl_rs_ServiceOffer()
{
}

::CORBA::StaticValueType _Marshaller_openbusidl_rs_ServiceOffer::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_openbusidl_rs_ServiceOffer::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_openbusidl_rs_ServiceOffer::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_openbusidl_rs_ServiceOffer::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  return
    dc.struct_begin() &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->type._for_demarshal() ) &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->description._for_demarshal() ) &&
    _marshaller__seq_openbusidl_rs_Property->demarshal( dc, &((_MICO_T*)v)->properties ) &&
    _marshaller_scs_core_IComponent->demarshal( dc, &((_MICO_T*)v)->member._for_demarshal() ) &&
    dc.struct_end();
}

void _Marshaller_openbusidl_rs_ServiceOffer::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.struct_begin();
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->type.inout() );
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->description.inout() );
  _marshaller__seq_openbusidl_rs_Property->marshal( ec, &((_MICO_T*)v)->properties );
  _marshaller_scs_core_IComponent->marshal( ec, &((_MICO_T*)v)->member.inout() );
  ec.struct_end();
}

::CORBA::StaticTypeInfo *_marshaller_openbusidl_rs_ServiceOffer;




/*
 * Base interface for class IRegistryService
 */

openbusidl::rs::IRegistryService::~IRegistryService()
{
}

void *
openbusidl::rs::IRegistryService::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:openbusidl/rs/IRegistryService:1.0" ) == 0 )
    return (void *)this;
  {
    void *_p;
    if ((_p = scs::core::IComponent::_narrow_helper( _repoid )))
      return _p;
  }
  return NULL;
}

openbusidl::rs::IRegistryService_ptr
openbusidl::rs::IRegistryService::_narrow( CORBA::Object_ptr _obj )
{
  openbusidl::rs::IRegistryService_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:openbusidl/rs/IRegistryService:1.0" )))
      return _duplicate( (openbusidl::rs::IRegistryService_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:openbusidl/rs/IRegistryService:1.0") || _obj->_is_a_remote ("IDL:openbusidl/rs/IRegistryService:1.0")) {
      _o = new openbusidl::rs::IRegistryService_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

openbusidl::rs::IRegistryService_ptr
openbusidl::rs::IRegistryService::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

class _Marshaller_openbusidl_rs_IRegistryService : public ::CORBA::StaticTypeInfo {
    typedef openbusidl::rs::IRegistryService_ptr _MICO_T;
  public:
    ~_Marshaller_openbusidl_rs_IRegistryService();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_openbusidl_rs_IRegistryService::~_Marshaller_openbusidl_rs_IRegistryService()
{
}

::CORBA::StaticValueType _Marshaller_openbusidl_rs_IRegistryService::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_openbusidl_rs_IRegistryService::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::openbusidl::rs::IRegistryService::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_openbusidl_rs_IRegistryService::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_openbusidl_rs_IRegistryService::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_openbusidl_rs_IRegistryService::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::openbusidl::rs::IRegistryService::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_openbusidl_rs_IRegistryService::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::StaticTypeInfo *_marshaller_openbusidl_rs_IRegistryService;


/*
 * Stub interface for class IRegistryService
 */

openbusidl::rs::IRegistryService_stub::~IRegistryService_stub()
{
}

CORBA::Boolean openbusidl::rs::IRegistryService_stub::_cxx_register( const openbusidl::rs::ServiceOffer& _par_aServiceOffer, CORBA::String_out _par_identifier )
{
  CORBA::StaticAny _sa_aServiceOffer( _marshaller_openbusidl_rs_ServiceOffer, &_par_aServiceOffer );
  CORBA::StaticAny _sa_identifier( CORBA::_stc_string, &_par_identifier.ptr() );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "register" );
  __req.add_in_arg( &_sa_aServiceOffer );
  __req.add_out_arg( &_sa_identifier );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


CORBA::Boolean openbusidl::rs::IRegistryService_stub::unregister( const char* _par_identifier )
{
  CORBA::StaticAny _sa_identifier( CORBA::_stc_string, &_par_identifier );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "unregister" );
  __req.add_in_arg( &_sa_identifier );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


CORBA::Boolean openbusidl::rs::IRegistryService_stub::update( const char* _par_identifier, const openbusidl::rs::PropertyList& _par_newProperties )
{
  CORBA::StaticAny _sa_identifier( CORBA::_stc_string, &_par_identifier );
  CORBA::StaticAny _sa_newProperties( _marshaller__seq_openbusidl_rs_Property, &_par_newProperties );
  CORBA::Boolean _res;
  CORBA::StaticAny __res( CORBA::_stc_boolean, &_res );

  CORBA::StaticRequest __req( this, "update" );
  __req.add_in_arg( &_sa_identifier );
  __req.add_in_arg( &_sa_newProperties );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


openbusidl::rs::ServiceOfferList* openbusidl::rs::IRegistryService_stub::find( const char* _par_type, const openbusidl::rs::PropertyList& _par_criteria )
{
  CORBA::StaticAny _sa_type( CORBA::_stc_string, &_par_type );
  CORBA::StaticAny _sa_criteria( _marshaller__seq_openbusidl_rs_Property, &_par_criteria );
  CORBA::StaticAny __res( _marshaller__seq_openbusidl_rs_ServiceOffer );

  CORBA::StaticRequest __req( this, "find" );
  __req.add_in_arg( &_sa_type );
  __req.add_in_arg( &_sa_criteria );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return (openbusidl::rs::ServiceOfferList*) __res._retn();
}


class _Marshaller__seq_openbusidl_rs_Property : public ::CORBA::StaticTypeInfo {
    typedef SequenceTmpl< openbusidl::rs::Property,MICO_TID_DEF> _MICO_T;
  public:
    ~_Marshaller__seq_openbusidl_rs_Property();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller__seq_openbusidl_rs_Property::~_Marshaller__seq_openbusidl_rs_Property()
{
}

::CORBA::StaticValueType _Marshaller__seq_openbusidl_rs_Property::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller__seq_openbusidl_rs_Property::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller__seq_openbusidl_rs_Property::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller__seq_openbusidl_rs_Property::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::ULong len;
  if( !dc.seq_begin( len ) )
    return FALSE;
  ((_MICO_T *) v)->length( len );
  for( ::CORBA::ULong i = 0; i < len; i++ ) {
    if( !_marshaller_openbusidl_rs_Property->demarshal( dc, &(*(_MICO_T*)v)[i] ) )
      return FALSE;
  }
  return dc.seq_end();
}

void _Marshaller__seq_openbusidl_rs_Property::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::ULong len = ((_MICO_T *) v)->length();
  ec.seq_begin( len );
  for( ::CORBA::ULong i = 0; i < len; i++ )
    _marshaller_openbusidl_rs_Property->marshal( ec, &(*(_MICO_T*)v)[i] );
  ec.seq_end();
}

::CORBA::StaticTypeInfo *_marshaller__seq_openbusidl_rs_Property;

class _Marshaller__seq_openbusidl_rs_ServiceOffer : public ::CORBA::StaticTypeInfo {
    typedef SequenceTmpl< openbusidl::rs::ServiceOffer,MICO_TID_DEF> _MICO_T;
  public:
    ~_Marshaller__seq_openbusidl_rs_ServiceOffer();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller__seq_openbusidl_rs_ServiceOffer::~_Marshaller__seq_openbusidl_rs_ServiceOffer()
{
}

::CORBA::StaticValueType _Marshaller__seq_openbusidl_rs_ServiceOffer::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller__seq_openbusidl_rs_ServiceOffer::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller__seq_openbusidl_rs_ServiceOffer::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller__seq_openbusidl_rs_ServiceOffer::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::ULong len;
  if( !dc.seq_begin( len ) )
    return FALSE;
  ((_MICO_T *) v)->length( len );
  for( ::CORBA::ULong i = 0; i < len; i++ ) {
    if( !_marshaller_openbusidl_rs_ServiceOffer->demarshal( dc, &(*(_MICO_T*)v)[i] ) )
      return FALSE;
  }
  return dc.seq_end();
}

void _Marshaller__seq_openbusidl_rs_ServiceOffer::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::ULong len = ((_MICO_T *) v)->length();
  ec.seq_begin( len );
  for( ::CORBA::ULong i = 0; i < len; i++ )
    _marshaller_openbusidl_rs_ServiceOffer->marshal( ec, &(*(_MICO_T*)v)[i] );
  ec.seq_end();
}

::CORBA::StaticTypeInfo *_marshaller__seq_openbusidl_rs_ServiceOffer;

struct __tc_init_REGISTRY_SERVICE {
  __tc_init_REGISTRY_SERVICE()
  {
    _marshaller_openbusidl_rs_Property = new _Marshaller_openbusidl_rs_Property;
    _marshaller_openbusidl_rs_ServiceOffer = new _Marshaller_openbusidl_rs_ServiceOffer;
    _marshaller_openbusidl_rs_IRegistryService = new _Marshaller_openbusidl_rs_IRegistryService;
    _marshaller__seq_openbusidl_rs_Property = new _Marshaller__seq_openbusidl_rs_Property;
    _marshaller__seq_openbusidl_rs_ServiceOffer = new _Marshaller__seq_openbusidl_rs_ServiceOffer;
  }

  ~__tc_init_REGISTRY_SERVICE()
  {
    delete static_cast<_Marshaller_openbusidl_rs_Property*>(_marshaller_openbusidl_rs_Property);
    delete static_cast<_Marshaller_openbusidl_rs_ServiceOffer*>(_marshaller_openbusidl_rs_ServiceOffer);
    delete static_cast<_Marshaller_openbusidl_rs_IRegistryService*>(_marshaller_openbusidl_rs_IRegistryService);
    delete static_cast<_Marshaller__seq_openbusidl_rs_Property*>(_marshaller__seq_openbusidl_rs_Property);
    delete static_cast<_Marshaller__seq_openbusidl_rs_ServiceOffer*>(_marshaller__seq_openbusidl_rs_ServiceOffer);
  }
};

static __tc_init_REGISTRY_SERVICE __init_REGISTRY_SERVICE;

//--------------------------------------------------------
//  Implementation of skeletons
//--------------------------------------------------------
