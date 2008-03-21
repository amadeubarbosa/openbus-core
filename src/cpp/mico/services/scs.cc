/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <openbus/mico/services/scs.h>


using namespace std;

//--------------------------------------------------------
//  Implementation of stubs
//--------------------------------------------------------

#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::StartupFailed::StartupFailed()
{
}

scs::core::StartupFailed::StartupFailed( const StartupFailed& _s )
{
}

scs::core::StartupFailed::~StartupFailed()
{
}

scs::core::StartupFailed&
scs::core::StartupFailed::operator=( const StartupFailed& _s )
{
  return *this;
}
#endif

class _Marshaller_scs_core_StartupFailed : public ::CORBA::StaticTypeInfo {
    typedef ::scs::core::StartupFailed _MICO_T;
  public:
    ~_Marshaller_scs_core_StartupFailed();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_StartupFailed::~_Marshaller_scs_core_StartupFailed()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_StartupFailed::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_StartupFailed::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_StartupFailed::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_StartupFailed::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  string repoid;
  return
    dc.except_begin( repoid ) &&
    dc.except_end();
}

void _Marshaller_scs_core_StartupFailed::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.except_begin( "IDL:scs/core/StartupFailed:1.0" );
  ec.except_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_StartupFailed;

void scs::core::StartupFailed::_throwit() const
{
  #ifdef HAVE_EXCEPTIONS
  #ifdef HAVE_STD_EH
  throw *this;
  #else
  throw StartupFailed_var( (scs::core::StartupFailed*)_clone() );
  #endif
  #else
  CORBA::Exception::_throw_failed( _clone() );
  #endif
}

const char *scs::core::StartupFailed::_repoid() const
{
  return "IDL:scs/core/StartupFailed:1.0";
}

void scs::core::StartupFailed::_encode( CORBA::DataEncoder &_en ) const
{
  _marshaller_scs_core_StartupFailed->marshal( _en, (void*) this );
}

void scs::core::StartupFailed::_encode_any( CORBA::Any & ) const
{
  // use --any to make this work!
  assert(0);
}

CORBA::Exception *scs::core::StartupFailed::_clone() const
{
  return new StartupFailed( *this );
}

scs::core::StartupFailed *scs::core::StartupFailed::_downcast( CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/StartupFailed:1.0" ) )
    return (StartupFailed *) _ex;
  return NULL;
}

const scs::core::StartupFailed *scs::core::StartupFailed::_downcast( const CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/StartupFailed:1.0" ) )
    return (StartupFailed *) _ex;
  return NULL;
}


#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::ShutdownFailed::ShutdownFailed()
{
}

scs::core::ShutdownFailed::ShutdownFailed( const ShutdownFailed& _s )
{
}

scs::core::ShutdownFailed::~ShutdownFailed()
{
}

scs::core::ShutdownFailed&
scs::core::ShutdownFailed::operator=( const ShutdownFailed& _s )
{
  return *this;
}
#endif

class _Marshaller_scs_core_ShutdownFailed : public ::CORBA::StaticTypeInfo {
    typedef ::scs::core::ShutdownFailed _MICO_T;
  public:
    ~_Marshaller_scs_core_ShutdownFailed();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_ShutdownFailed::~_Marshaller_scs_core_ShutdownFailed()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_ShutdownFailed::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_ShutdownFailed::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_ShutdownFailed::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_ShutdownFailed::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  string repoid;
  return
    dc.except_begin( repoid ) &&
    dc.except_end();
}

void _Marshaller_scs_core_ShutdownFailed::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.except_begin( "IDL:scs/core/ShutdownFailed:1.0" );
  ec.except_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_ShutdownFailed;

void scs::core::ShutdownFailed::_throwit() const
{
  #ifdef HAVE_EXCEPTIONS
  #ifdef HAVE_STD_EH
  throw *this;
  #else
  throw ShutdownFailed_var( (scs::core::ShutdownFailed*)_clone() );
  #endif
  #else
  CORBA::Exception::_throw_failed( _clone() );
  #endif
}

const char *scs::core::ShutdownFailed::_repoid() const
{
  return "IDL:scs/core/ShutdownFailed:1.0";
}

void scs::core::ShutdownFailed::_encode( CORBA::DataEncoder &_en ) const
{
  _marshaller_scs_core_ShutdownFailed->marshal( _en, (void*) this );
}

void scs::core::ShutdownFailed::_encode_any( CORBA::Any & ) const
{
  // use --any to make this work!
  assert(0);
}

CORBA::Exception *scs::core::ShutdownFailed::_clone() const
{
  return new ShutdownFailed( *this );
}

scs::core::ShutdownFailed *scs::core::ShutdownFailed::_downcast( CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/ShutdownFailed:1.0" ) )
    return (ShutdownFailed *) _ex;
  return NULL;
}

const scs::core::ShutdownFailed *scs::core::ShutdownFailed::_downcast( const CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/ShutdownFailed:1.0" ) )
    return (ShutdownFailed *) _ex;
  return NULL;
}


#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::InvalidName::InvalidName()
{
}

scs::core::InvalidName::InvalidName( const InvalidName& _s )
{
  name = ((InvalidName&)_s).name;
}

scs::core::InvalidName::~InvalidName()
{
}

scs::core::InvalidName&
scs::core::InvalidName::operator=( const InvalidName& _s )
{
  name = ((InvalidName&)_s).name;
  return *this;
}
#endif

#ifndef HAVE_EXPLICIT_STRUCT_OPS
scs::core::InvalidName::InvalidName()
{
}

#endif

scs::core::InvalidName::InvalidName( const char* _m0 )
{
  name = _m0;
}

class _Marshaller_scs_core_InvalidName : public ::CORBA::StaticTypeInfo {
    typedef ::scs::core::InvalidName _MICO_T;
  public:
    ~_Marshaller_scs_core_InvalidName();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_InvalidName::~_Marshaller_scs_core_InvalidName()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_InvalidName::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_InvalidName::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_InvalidName::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_InvalidName::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  string repoid;
  return
    dc.except_begin( repoid ) &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->name._for_demarshal() ) &&
    dc.except_end();
}

void _Marshaller_scs_core_InvalidName::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.except_begin( "IDL:scs/core/InvalidName:1.0" );
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->name.inout() );
  ec.except_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_InvalidName;

void scs::core::InvalidName::_throwit() const
{
  #ifdef HAVE_EXCEPTIONS
  #ifdef HAVE_STD_EH
  throw *this;
  #else
  throw InvalidName_var( (scs::core::InvalidName*)_clone() );
  #endif
  #else
  CORBA::Exception::_throw_failed( _clone() );
  #endif
}

const char *scs::core::InvalidName::_repoid() const
{
  return "IDL:scs/core/InvalidName:1.0";
}

void scs::core::InvalidName::_encode( CORBA::DataEncoder &_en ) const
{
  _marshaller_scs_core_InvalidName->marshal( _en, (void*) this );
}

void scs::core::InvalidName::_encode_any( CORBA::Any & ) const
{
  // use --any to make this work!
  assert(0);
}

CORBA::Exception *scs::core::InvalidName::_clone() const
{
  return new InvalidName( *this );
}

scs::core::InvalidName *scs::core::InvalidName::_downcast( CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/InvalidName:1.0" ) )
    return (InvalidName *) _ex;
  return NULL;
}

const scs::core::InvalidName *scs::core::InvalidName::_downcast( const CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/InvalidName:1.0" ) )
    return (InvalidName *) _ex;
  return NULL;
}


#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::InvalidConnection::InvalidConnection()
{
}

scs::core::InvalidConnection::InvalidConnection( const InvalidConnection& _s )
{
}

scs::core::InvalidConnection::~InvalidConnection()
{
}

scs::core::InvalidConnection&
scs::core::InvalidConnection::operator=( const InvalidConnection& _s )
{
  return *this;
}
#endif

class _Marshaller_scs_core_InvalidConnection : public ::CORBA::StaticTypeInfo {
    typedef ::scs::core::InvalidConnection _MICO_T;
  public:
    ~_Marshaller_scs_core_InvalidConnection();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_InvalidConnection::~_Marshaller_scs_core_InvalidConnection()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_InvalidConnection::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_InvalidConnection::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_InvalidConnection::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_InvalidConnection::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  string repoid;
  return
    dc.except_begin( repoid ) &&
    dc.except_end();
}

void _Marshaller_scs_core_InvalidConnection::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.except_begin( "IDL:scs/core/InvalidConnection:1.0" );
  ec.except_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_InvalidConnection;

void scs::core::InvalidConnection::_throwit() const
{
  #ifdef HAVE_EXCEPTIONS
  #ifdef HAVE_STD_EH
  throw *this;
  #else
  throw InvalidConnection_var( (scs::core::InvalidConnection*)_clone() );
  #endif
  #else
  CORBA::Exception::_throw_failed( _clone() );
  #endif
}

const char *scs::core::InvalidConnection::_repoid() const
{
  return "IDL:scs/core/InvalidConnection:1.0";
}

void scs::core::InvalidConnection::_encode( CORBA::DataEncoder &_en ) const
{
  _marshaller_scs_core_InvalidConnection->marshal( _en, (void*) this );
}

void scs::core::InvalidConnection::_encode_any( CORBA::Any & ) const
{
  // use --any to make this work!
  assert(0);
}

CORBA::Exception *scs::core::InvalidConnection::_clone() const
{
  return new InvalidConnection( *this );
}

scs::core::InvalidConnection *scs::core::InvalidConnection::_downcast( CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/InvalidConnection:1.0" ) )
    return (InvalidConnection *) _ex;
  return NULL;
}

const scs::core::InvalidConnection *scs::core::InvalidConnection::_downcast( const CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/InvalidConnection:1.0" ) )
    return (InvalidConnection *) _ex;
  return NULL;
}


#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::AlreadyConnected::AlreadyConnected()
{
}

scs::core::AlreadyConnected::AlreadyConnected( const AlreadyConnected& _s )
{
}

scs::core::AlreadyConnected::~AlreadyConnected()
{
}

scs::core::AlreadyConnected&
scs::core::AlreadyConnected::operator=( const AlreadyConnected& _s )
{
  return *this;
}
#endif

class _Marshaller_scs_core_AlreadyConnected : public ::CORBA::StaticTypeInfo {
    typedef ::scs::core::AlreadyConnected _MICO_T;
  public:
    ~_Marshaller_scs_core_AlreadyConnected();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_AlreadyConnected::~_Marshaller_scs_core_AlreadyConnected()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_AlreadyConnected::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_AlreadyConnected::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_AlreadyConnected::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_AlreadyConnected::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  string repoid;
  return
    dc.except_begin( repoid ) &&
    dc.except_end();
}

void _Marshaller_scs_core_AlreadyConnected::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.except_begin( "IDL:scs/core/AlreadyConnected:1.0" );
  ec.except_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_AlreadyConnected;

void scs::core::AlreadyConnected::_throwit() const
{
  #ifdef HAVE_EXCEPTIONS
  #ifdef HAVE_STD_EH
  throw *this;
  #else
  throw AlreadyConnected_var( (scs::core::AlreadyConnected*)_clone() );
  #endif
  #else
  CORBA::Exception::_throw_failed( _clone() );
  #endif
}

const char *scs::core::AlreadyConnected::_repoid() const
{
  return "IDL:scs/core/AlreadyConnected:1.0";
}

void scs::core::AlreadyConnected::_encode( CORBA::DataEncoder &_en ) const
{
  _marshaller_scs_core_AlreadyConnected->marshal( _en, (void*) this );
}

void scs::core::AlreadyConnected::_encode_any( CORBA::Any & ) const
{
  // use --any to make this work!
  assert(0);
}

CORBA::Exception *scs::core::AlreadyConnected::_clone() const
{
  return new AlreadyConnected( *this );
}

scs::core::AlreadyConnected *scs::core::AlreadyConnected::_downcast( CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/AlreadyConnected:1.0" ) )
    return (AlreadyConnected *) _ex;
  return NULL;
}

const scs::core::AlreadyConnected *scs::core::AlreadyConnected::_downcast( const CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/AlreadyConnected:1.0" ) )
    return (AlreadyConnected *) _ex;
  return NULL;
}


#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::ExceededConnectionLimit::ExceededConnectionLimit()
{
}

scs::core::ExceededConnectionLimit::ExceededConnectionLimit( const ExceededConnectionLimit& _s )
{
}

scs::core::ExceededConnectionLimit::~ExceededConnectionLimit()
{
}

scs::core::ExceededConnectionLimit&
scs::core::ExceededConnectionLimit::operator=( const ExceededConnectionLimit& _s )
{
  return *this;
}
#endif

class _Marshaller_scs_core_ExceededConnectionLimit : public ::CORBA::StaticTypeInfo {
    typedef ::scs::core::ExceededConnectionLimit _MICO_T;
  public:
    ~_Marshaller_scs_core_ExceededConnectionLimit();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_ExceededConnectionLimit::~_Marshaller_scs_core_ExceededConnectionLimit()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_ExceededConnectionLimit::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_ExceededConnectionLimit::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_ExceededConnectionLimit::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_ExceededConnectionLimit::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  string repoid;
  return
    dc.except_begin( repoid ) &&
    dc.except_end();
}

void _Marshaller_scs_core_ExceededConnectionLimit::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.except_begin( "IDL:scs/core/ExceededConnectionLimit:1.0" );
  ec.except_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_ExceededConnectionLimit;

void scs::core::ExceededConnectionLimit::_throwit() const
{
  #ifdef HAVE_EXCEPTIONS
  #ifdef HAVE_STD_EH
  throw *this;
  #else
  throw ExceededConnectionLimit_var( (scs::core::ExceededConnectionLimit*)_clone() );
  #endif
  #else
  CORBA::Exception::_throw_failed( _clone() );
  #endif
}

const char *scs::core::ExceededConnectionLimit::_repoid() const
{
  return "IDL:scs/core/ExceededConnectionLimit:1.0";
}

void scs::core::ExceededConnectionLimit::_encode( CORBA::DataEncoder &_en ) const
{
  _marshaller_scs_core_ExceededConnectionLimit->marshal( _en, (void*) this );
}

void scs::core::ExceededConnectionLimit::_encode_any( CORBA::Any & ) const
{
  // use --any to make this work!
  assert(0);
}

CORBA::Exception *scs::core::ExceededConnectionLimit::_clone() const
{
  return new ExceededConnectionLimit( *this );
}

scs::core::ExceededConnectionLimit *scs::core::ExceededConnectionLimit::_downcast( CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/ExceededConnectionLimit:1.0" ) )
    return (ExceededConnectionLimit *) _ex;
  return NULL;
}

const scs::core::ExceededConnectionLimit *scs::core::ExceededConnectionLimit::_downcast( const CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/ExceededConnectionLimit:1.0" ) )
    return (ExceededConnectionLimit *) _ex;
  return NULL;
}


#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::NoConnection::NoConnection()
{
}

scs::core::NoConnection::NoConnection( const NoConnection& _s )
{
}

scs::core::NoConnection::~NoConnection()
{
}

scs::core::NoConnection&
scs::core::NoConnection::operator=( const NoConnection& _s )
{
  return *this;
}
#endif

class _Marshaller_scs_core_NoConnection : public ::CORBA::StaticTypeInfo {
    typedef ::scs::core::NoConnection _MICO_T;
  public:
    ~_Marshaller_scs_core_NoConnection();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_NoConnection::~_Marshaller_scs_core_NoConnection()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_NoConnection::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_NoConnection::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_NoConnection::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_NoConnection::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  string repoid;
  return
    dc.except_begin( repoid ) &&
    dc.except_end();
}

void _Marshaller_scs_core_NoConnection::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.except_begin( "IDL:scs/core/NoConnection:1.0" );
  ec.except_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_NoConnection;

void scs::core::NoConnection::_throwit() const
{
  #ifdef HAVE_EXCEPTIONS
  #ifdef HAVE_STD_EH
  throw *this;
  #else
  throw NoConnection_var( (scs::core::NoConnection*)_clone() );
  #endif
  #else
  CORBA::Exception::_throw_failed( _clone() );
  #endif
}

const char *scs::core::NoConnection::_repoid() const
{
  return "IDL:scs/core/NoConnection:1.0";
}

void scs::core::NoConnection::_encode( CORBA::DataEncoder &_en ) const
{
  _marshaller_scs_core_NoConnection->marshal( _en, (void*) this );
}

void scs::core::NoConnection::_encode_any( CORBA::Any & ) const
{
  // use --any to make this work!
  assert(0);
}

CORBA::Exception *scs::core::NoConnection::_clone() const
{
  return new NoConnection( *this );
}

scs::core::NoConnection *scs::core::NoConnection::_downcast( CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/NoConnection:1.0" ) )
    return (NoConnection *) _ex;
  return NULL;
}

const scs::core::NoConnection *scs::core::NoConnection::_downcast( const CORBA::Exception *_ex )
{
  if( _ex && !strcmp( _ex->_repoid(), "IDL:scs/core/NoConnection:1.0" ) )
    return (NoConnection *) _ex;
  return NULL;
}



#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::FacetDescription::FacetDescription()
{
}

scs::core::FacetDescription::FacetDescription( const FacetDescription& _s )
{
  name = ((FacetDescription&)_s).name;
  interface_name = ((FacetDescription&)_s).interface_name;
  facet_ref = ((FacetDescription&)_s).facet_ref;
}

scs::core::FacetDescription::~FacetDescription()
{
}

scs::core::FacetDescription&
scs::core::FacetDescription::operator=( const FacetDescription& _s )
{
  name = ((FacetDescription&)_s).name;
  interface_name = ((FacetDescription&)_s).interface_name;
  facet_ref = ((FacetDescription&)_s).facet_ref;
  return *this;
}
#endif

class _Marshaller_scs_core_FacetDescription : public ::CORBA::StaticTypeInfo {
    typedef scs::core::FacetDescription _MICO_T;
  public:
    ~_Marshaller_scs_core_FacetDescription();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_FacetDescription::~_Marshaller_scs_core_FacetDescription()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_FacetDescription::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_FacetDescription::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_FacetDescription::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_FacetDescription::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  return
    dc.struct_begin() &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->name._for_demarshal() ) &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->interface_name._for_demarshal() ) &&
    CORBA::_stc_Object->demarshal( dc, &((_MICO_T*)v)->facet_ref._for_demarshal() ) &&
    dc.struct_end();
}

void _Marshaller_scs_core_FacetDescription::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.struct_begin();
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->name.inout() );
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->interface_name.inout() );
  CORBA::_stc_Object->marshal( ec, &((_MICO_T*)v)->facet_ref.inout() );
  ec.struct_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_FacetDescription;


#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::ConnectionDescription::ConnectionDescription()
{
}

scs::core::ConnectionDescription::ConnectionDescription( const ConnectionDescription& _s )
{
  id = ((ConnectionDescription&)_s).id;
  objref = ((ConnectionDescription&)_s).objref;
}

scs::core::ConnectionDescription::~ConnectionDescription()
{
}

scs::core::ConnectionDescription&
scs::core::ConnectionDescription::operator=( const ConnectionDescription& _s )
{
  id = ((ConnectionDescription&)_s).id;
  objref = ((ConnectionDescription&)_s).objref;
  return *this;
}
#endif

class _Marshaller_scs_core_ConnectionDescription : public ::CORBA::StaticTypeInfo {
    typedef scs::core::ConnectionDescription _MICO_T;
  public:
    ~_Marshaller_scs_core_ConnectionDescription();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_ConnectionDescription::~_Marshaller_scs_core_ConnectionDescription()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_ConnectionDescription::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_ConnectionDescription::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_ConnectionDescription::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_ConnectionDescription::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  return
    dc.struct_begin() &&
    CORBA::_stc_ulong->demarshal( dc, &((_MICO_T*)v)->id ) &&
    CORBA::_stc_Object->demarshal( dc, &((_MICO_T*)v)->objref._for_demarshal() ) &&
    dc.struct_end();
}

void _Marshaller_scs_core_ConnectionDescription::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.struct_begin();
  CORBA::_stc_ulong->marshal( ec, &((_MICO_T*)v)->id );
  CORBA::_stc_Object->marshal( ec, &((_MICO_T*)v)->objref.inout() );
  ec.struct_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_ConnectionDescription;


#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::ReceptacleDescription::ReceptacleDescription()
{
}

scs::core::ReceptacleDescription::ReceptacleDescription( const ReceptacleDescription& _s )
{
  name = ((ReceptacleDescription&)_s).name;
  interface_name = ((ReceptacleDescription&)_s).interface_name;
  is_multiplex = ((ReceptacleDescription&)_s).is_multiplex;
  connections = ((ReceptacleDescription&)_s).connections;
}

scs::core::ReceptacleDescription::~ReceptacleDescription()
{
}

scs::core::ReceptacleDescription&
scs::core::ReceptacleDescription::operator=( const ReceptacleDescription& _s )
{
  name = ((ReceptacleDescription&)_s).name;
  interface_name = ((ReceptacleDescription&)_s).interface_name;
  is_multiplex = ((ReceptacleDescription&)_s).is_multiplex;
  connections = ((ReceptacleDescription&)_s).connections;
  return *this;
}
#endif

class _Marshaller_scs_core_ReceptacleDescription : public ::CORBA::StaticTypeInfo {
    typedef scs::core::ReceptacleDescription _MICO_T;
  public:
    ~_Marshaller_scs_core_ReceptacleDescription();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_ReceptacleDescription::~_Marshaller_scs_core_ReceptacleDescription()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_ReceptacleDescription::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_ReceptacleDescription::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_ReceptacleDescription::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_ReceptacleDescription::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  return
    dc.struct_begin() &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->name._for_demarshal() ) &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->interface_name._for_demarshal() ) &&
    CORBA::_stc_boolean->demarshal( dc, &((_MICO_T*)v)->is_multiplex ) &&
    _marshaller__seq_scs_core_ConnectionDescription->demarshal( dc, &((_MICO_T*)v)->connections ) &&
    dc.struct_end();
}

void _Marshaller_scs_core_ReceptacleDescription::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.struct_begin();
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->name.inout() );
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->interface_name.inout() );
  CORBA::_stc_boolean->marshal( ec, &((_MICO_T*)v)->is_multiplex );
  _marshaller__seq_scs_core_ConnectionDescription->marshal( ec, &((_MICO_T*)v)->connections );
  ec.struct_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_ReceptacleDescription;


#ifdef HAVE_EXPLICIT_STRUCT_OPS
scs::core::ComponentId::ComponentId()
{
}

scs::core::ComponentId::ComponentId( const ComponentId& _s )
{
  name = ((ComponentId&)_s).name;
  version = ((ComponentId&)_s).version;
}

scs::core::ComponentId::~ComponentId()
{
}

scs::core::ComponentId&
scs::core::ComponentId::operator=( const ComponentId& _s )
{
  name = ((ComponentId&)_s).name;
  version = ((ComponentId&)_s).version;
  return *this;
}
#endif

class _Marshaller_scs_core_ComponentId : public ::CORBA::StaticTypeInfo {
    typedef scs::core::ComponentId _MICO_T;
  public:
    ~_Marshaller_scs_core_ComponentId();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_ComponentId::~_Marshaller_scs_core_ComponentId()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_ComponentId::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller_scs_core_ComponentId::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller_scs_core_ComponentId::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller_scs_core_ComponentId::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  return
    dc.struct_begin() &&
    CORBA::_stc_string->demarshal( dc, &((_MICO_T*)v)->name._for_demarshal() ) &&
    CORBA::_stc_ulong->demarshal( dc, &((_MICO_T*)v)->version ) &&
    dc.struct_end();
}

void _Marshaller_scs_core_ComponentId::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ec.struct_begin();
  CORBA::_stc_string->marshal( ec, &((_MICO_T*)v)->name.inout() );
  CORBA::_stc_ulong->marshal( ec, &((_MICO_T*)v)->version );
  ec.struct_end();
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_ComponentId;



/*
 * Base interface for class IComponent
 */

scs::core::IComponent::~IComponent()
{
}

void *
scs::core::IComponent::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:scs/core/IComponent:1.0" ) == 0 )
    return (void *)this;
  return NULL;
}

scs::core::IComponent_ptr
scs::core::IComponent::_narrow( CORBA::Object_ptr _obj )
{
  scs::core::IComponent_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:scs/core/IComponent:1.0" )))
      return _duplicate( (scs::core::IComponent_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:scs/core/IComponent:1.0") || _obj->_is_a_remote ("IDL:scs/core/IComponent:1.0")) {
      _o = new scs::core::IComponent_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

scs::core::IComponent_ptr
scs::core::IComponent::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

class _Marshaller_scs_core_IComponent : public ::CORBA::StaticTypeInfo {
    typedef scs::core::IComponent_ptr _MICO_T;
  public:
    ~_Marshaller_scs_core_IComponent();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_IComponent::~_Marshaller_scs_core_IComponent()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_IComponent::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_scs_core_IComponent::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::scs::core::IComponent::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_scs_core_IComponent::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_scs_core_IComponent::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_scs_core_IComponent::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::scs::core::IComponent::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_scs_core_IComponent::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_IComponent;


/*
 * Stub interface for class IComponent
 */

scs::core::IComponent_stub::~IComponent_stub()
{
}

#ifndef MICO_CONF_NO_POA

void *
POA_scs::core::IComponent::_narrow_helper (const char * repoid)
{
  if (strcmp (repoid, "IDL:scs/core/IComponent:1.0") == 0) {
    return (void *) this;
  }
  return NULL;
}

POA_scs::core::IComponent *
POA_scs::core::IComponent::_narrow (PortableServer::Servant serv) 
{
  void * p;
  if ((p = serv->_narrow_helper ("IDL:scs/core/IComponent:1.0")) != NULL) {
    serv->_add_ref ();
    return (POA_scs::core::IComponent *) p;
  }
  return NULL;
}

scs::core::IComponent_stub_clp::IComponent_stub_clp ()
{
}

scs::core::IComponent_stub_clp::IComponent_stub_clp (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
  : CORBA::Object(*obj), PortableServer::StubBase(poa)
{
}

scs::core::IComponent_stub_clp::~IComponent_stub_clp ()
{
}

#endif // MICO_CONF_NO_POA

void scs::core::IComponent_stub::startup()
{
  CORBA::StaticRequest __req( this, "startup" );

  __req.invoke();

  mico_sii_throw( &__req, 
    _marshaller_scs_core_StartupFailed, "IDL:scs/core/StartupFailed:1.0",
    0);
}


#ifndef MICO_CONF_NO_POA

void
scs::core::IComponent_stub_clp::startup()
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IComponent * _myserv = POA_scs::core::IComponent::_narrow (_serv);
    if (_myserv) {
      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        _myserv->startup();
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return;
    }
    _postinvoke ();
  }

  scs::core::IComponent_stub::startup();
}

#endif // MICO_CONF_NO_POA

void scs::core::IComponent_stub::shutdown()
{
  CORBA::StaticRequest __req( this, "shutdown" );

  __req.invoke();

  mico_sii_throw( &__req, 
    _marshaller_scs_core_ShutdownFailed, "IDL:scs/core/ShutdownFailed:1.0",
    0);
}


#ifndef MICO_CONF_NO_POA

void
scs::core::IComponent_stub_clp::shutdown()
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IComponent * _myserv = POA_scs::core::IComponent::_narrow (_serv);
    if (_myserv) {
      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        _myserv->shutdown();
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return;
    }
    _postinvoke ();
  }

  scs::core::IComponent_stub::shutdown();
}

#endif // MICO_CONF_NO_POA

CORBA::Object_ptr scs::core::IComponent_stub::getFacet( const char* _par_facet_interface )
{
  CORBA::StaticAny _sa_facet_interface( CORBA::_stc_string, &_par_facet_interface );
  CORBA::Object_ptr _res = CORBA::Object::_nil();
  CORBA::StaticAny __res( CORBA::_stc_Object, &_res );

  CORBA::StaticRequest __req( this, "getFacet" );
  __req.add_in_arg( &_sa_facet_interface );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


#ifndef MICO_CONF_NO_POA

CORBA::Object_ptr
scs::core::IComponent_stub_clp::getFacet( const char* _par_facet_interface )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IComponent * _myserv = POA_scs::core::IComponent::_narrow (_serv);
    if (_myserv) {
      CORBA::Object_ptr __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->getFacet(_par_facet_interface);
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return scs::core::IComponent_stub::getFacet(_par_facet_interface);
}

#endif // MICO_CONF_NO_POA

CORBA::Object_ptr scs::core::IComponent_stub::getFacetByName( const char* _par_facet )
{
  CORBA::StaticAny _sa_facet( CORBA::_stc_string, &_par_facet );
  CORBA::Object_ptr _res = CORBA::Object::_nil();
  CORBA::StaticAny __res( CORBA::_stc_Object, &_res );

  CORBA::StaticRequest __req( this, "getFacetByName" );
  __req.add_in_arg( &_sa_facet );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


#ifndef MICO_CONF_NO_POA

CORBA::Object_ptr
scs::core::IComponent_stub_clp::getFacetByName( const char* _par_facet )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IComponent * _myserv = POA_scs::core::IComponent::_narrow (_serv);
    if (_myserv) {
      CORBA::Object_ptr __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->getFacetByName(_par_facet);
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return scs::core::IComponent_stub::getFacetByName(_par_facet);
}

#endif // MICO_CONF_NO_POA

scs::core::ComponentId* scs::core::IComponent_stub::getComponentId()
{
  CORBA::StaticAny __res( _marshaller_scs_core_ComponentId );

  CORBA::StaticRequest __req( this, "getComponentId" );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return (scs::core::ComponentId*) __res._retn();
}


#ifndef MICO_CONF_NO_POA

scs::core::ComponentId*
scs::core::IComponent_stub_clp::getComponentId()
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IComponent * _myserv = POA_scs::core::IComponent::_narrow (_serv);
    if (_myserv) {
      scs::core::ComponentId* __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->getComponentId();
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return scs::core::IComponent_stub::getComponentId();
}

#endif // MICO_CONF_NO_POA



/*
 * Base interface for class IReceptacles
 */

scs::core::IReceptacles::~IReceptacles()
{
}

void *
scs::core::IReceptacles::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:scs/core/IReceptacles:1.0" ) == 0 )
    return (void *)this;
  return NULL;
}

scs::core::IReceptacles_ptr
scs::core::IReceptacles::_narrow( CORBA::Object_ptr _obj )
{
  scs::core::IReceptacles_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:scs/core/IReceptacles:1.0" )))
      return _duplicate( (scs::core::IReceptacles_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:scs/core/IReceptacles:1.0") || _obj->_is_a_remote ("IDL:scs/core/IReceptacles:1.0")) {
      _o = new scs::core::IReceptacles_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

scs::core::IReceptacles_ptr
scs::core::IReceptacles::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

class _Marshaller_scs_core_IReceptacles : public ::CORBA::StaticTypeInfo {
    typedef scs::core::IReceptacles_ptr _MICO_T;
  public:
    ~_Marshaller_scs_core_IReceptacles();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_IReceptacles::~_Marshaller_scs_core_IReceptacles()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_IReceptacles::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_scs_core_IReceptacles::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::scs::core::IReceptacles::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_scs_core_IReceptacles::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_scs_core_IReceptacles::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_scs_core_IReceptacles::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::scs::core::IReceptacles::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_scs_core_IReceptacles::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_IReceptacles;


/*
 * Stub interface for class IReceptacles
 */

scs::core::IReceptacles_stub::~IReceptacles_stub()
{
}

#ifndef MICO_CONF_NO_POA

void *
POA_scs::core::IReceptacles::_narrow_helper (const char * repoid)
{
  if (strcmp (repoid, "IDL:scs/core/IReceptacles:1.0") == 0) {
    return (void *) this;
  }
  return NULL;
}

POA_scs::core::IReceptacles *
POA_scs::core::IReceptacles::_narrow (PortableServer::Servant serv) 
{
  void * p;
  if ((p = serv->_narrow_helper ("IDL:scs/core/IReceptacles:1.0")) != NULL) {
    serv->_add_ref ();
    return (POA_scs::core::IReceptacles *) p;
  }
  return NULL;
}

scs::core::IReceptacles_stub_clp::IReceptacles_stub_clp ()
{
}

scs::core::IReceptacles_stub_clp::IReceptacles_stub_clp (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
  : CORBA::Object(*obj), PortableServer::StubBase(poa)
{
}

scs::core::IReceptacles_stub_clp::~IReceptacles_stub_clp ()
{
}

#endif // MICO_CONF_NO_POA

scs::core::ConnectionId scs::core::IReceptacles_stub::connect( const char* _par_receptacle, CORBA::Object_ptr _par_obj )
{
  CORBA::StaticAny _sa_receptacle( CORBA::_stc_string, &_par_receptacle );
  CORBA::StaticAny _sa_obj( CORBA::_stc_Object, &_par_obj );
  scs::core::ConnectionId _res;
  CORBA::StaticAny __res( CORBA::_stc_ulong, &_res );

  CORBA::StaticRequest __req( this, "connect" );
  __req.add_in_arg( &_sa_receptacle );
  __req.add_in_arg( &_sa_obj );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    _marshaller_scs_core_InvalidName, "IDL:scs/core/InvalidName:1.0",
    _marshaller_scs_core_InvalidConnection, "IDL:scs/core/InvalidConnection:1.0",
    _marshaller_scs_core_AlreadyConnected, "IDL:scs/core/AlreadyConnected:1.0",
    _marshaller_scs_core_ExceededConnectionLimit, "IDL:scs/core/ExceededConnectionLimit:1.0",
    0);
  return _res;
}


#ifndef MICO_CONF_NO_POA

scs::core::ConnectionId
scs::core::IReceptacles_stub_clp::connect( const char* _par_receptacle, CORBA::Object_ptr _par_obj )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IReceptacles * _myserv = POA_scs::core::IReceptacles::_narrow (_serv);
    if (_myserv) {
      scs::core::ConnectionId __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->connect(_par_receptacle, _par_obj);
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return scs::core::IReceptacles_stub::connect(_par_receptacle, _par_obj);
}

#endif // MICO_CONF_NO_POA

void scs::core::IReceptacles_stub::disconnect( scs::core::ConnectionId _par_id )
{
  CORBA::StaticAny _sa_id( CORBA::_stc_ulong, &_par_id );
  CORBA::StaticRequest __req( this, "disconnect" );
  __req.add_in_arg( &_sa_id );

  __req.invoke();

  mico_sii_throw( &__req, 
    _marshaller_scs_core_InvalidConnection, "IDL:scs/core/InvalidConnection:1.0",
    _marshaller_scs_core_NoConnection, "IDL:scs/core/NoConnection:1.0",
    0);
}


#ifndef MICO_CONF_NO_POA

void
scs::core::IReceptacles_stub_clp::disconnect( scs::core::ConnectionId _par_id )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IReceptacles * _myserv = POA_scs::core::IReceptacles::_narrow (_serv);
    if (_myserv) {
      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        _myserv->disconnect(_par_id);
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return;
    }
    _postinvoke ();
  }

  scs::core::IReceptacles_stub::disconnect(_par_id);
}

#endif // MICO_CONF_NO_POA

scs::core::ConnectionDescriptions* scs::core::IReceptacles_stub::getConnections( const char* _par_receptacle )
{
  CORBA::StaticAny _sa_receptacle( CORBA::_stc_string, &_par_receptacle );
  CORBA::StaticAny __res( _marshaller__seq_scs_core_ConnectionDescription );

  CORBA::StaticRequest __req( this, "getConnections" );
  __req.add_in_arg( &_sa_receptacle );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    _marshaller_scs_core_InvalidName, "IDL:scs/core/InvalidName:1.0",
    0);
  return (scs::core::ConnectionDescriptions*) __res._retn();
}


#ifndef MICO_CONF_NO_POA

scs::core::ConnectionDescriptions*
scs::core::IReceptacles_stub_clp::getConnections( const char* _par_receptacle )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IReceptacles * _myserv = POA_scs::core::IReceptacles::_narrow (_serv);
    if (_myserv) {
      scs::core::ConnectionDescriptions* __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->getConnections(_par_receptacle);
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return scs::core::IReceptacles_stub::getConnections(_par_receptacle);
}

#endif // MICO_CONF_NO_POA


/*
 * Base interface for class IMetaInterface
 */

scs::core::IMetaInterface::~IMetaInterface()
{
}

void *
scs::core::IMetaInterface::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:scs/core/IMetaInterface:1.0" ) == 0 )
    return (void *)this;
  return NULL;
}

scs::core::IMetaInterface_ptr
scs::core::IMetaInterface::_narrow( CORBA::Object_ptr _obj )
{
  scs::core::IMetaInterface_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:scs/core/IMetaInterface:1.0" )))
      return _duplicate( (scs::core::IMetaInterface_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:scs/core/IMetaInterface:1.0") || _obj->_is_a_remote ("IDL:scs/core/IMetaInterface:1.0")) {
      _o = new scs::core::IMetaInterface_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

scs::core::IMetaInterface_ptr
scs::core::IMetaInterface::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

class _Marshaller_scs_core_IMetaInterface : public ::CORBA::StaticTypeInfo {
    typedef scs::core::IMetaInterface_ptr _MICO_T;
  public:
    ~_Marshaller_scs_core_IMetaInterface();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_scs_core_IMetaInterface::~_Marshaller_scs_core_IMetaInterface()
{
}

::CORBA::StaticValueType _Marshaller_scs_core_IMetaInterface::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_scs_core_IMetaInterface::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::scs::core::IMetaInterface::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_scs_core_IMetaInterface::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_scs_core_IMetaInterface::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_scs_core_IMetaInterface::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::scs::core::IMetaInterface::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_scs_core_IMetaInterface::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::StaticTypeInfo *_marshaller_scs_core_IMetaInterface;


/*
 * Stub interface for class IMetaInterface
 */

scs::core::IMetaInterface_stub::~IMetaInterface_stub()
{
}

#ifndef MICO_CONF_NO_POA

void *
POA_scs::core::IMetaInterface::_narrow_helper (const char * repoid)
{
  if (strcmp (repoid, "IDL:scs/core/IMetaInterface:1.0") == 0) {
    return (void *) this;
  }
  return NULL;
}

POA_scs::core::IMetaInterface *
POA_scs::core::IMetaInterface::_narrow (PortableServer::Servant serv) 
{
  void * p;
  if ((p = serv->_narrow_helper ("IDL:scs/core/IMetaInterface:1.0")) != NULL) {
    serv->_add_ref ();
    return (POA_scs::core::IMetaInterface *) p;
  }
  return NULL;
}

scs::core::IMetaInterface_stub_clp::IMetaInterface_stub_clp ()
{
}

scs::core::IMetaInterface_stub_clp::IMetaInterface_stub_clp (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
  : CORBA::Object(*obj), PortableServer::StubBase(poa)
{
}

scs::core::IMetaInterface_stub_clp::~IMetaInterface_stub_clp ()
{
}

#endif // MICO_CONF_NO_POA

scs::core::FacetDescriptions* scs::core::IMetaInterface_stub::getFacets()
{
  CORBA::StaticAny __res( _marshaller__seq_scs_core_FacetDescription );

  CORBA::StaticRequest __req( this, "getFacets" );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return (scs::core::FacetDescriptions*) __res._retn();
}


#ifndef MICO_CONF_NO_POA

scs::core::FacetDescriptions*
scs::core::IMetaInterface_stub_clp::getFacets()
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IMetaInterface * _myserv = POA_scs::core::IMetaInterface::_narrow (_serv);
    if (_myserv) {
      scs::core::FacetDescriptions* __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->getFacets();
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return scs::core::IMetaInterface_stub::getFacets();
}

#endif // MICO_CONF_NO_POA

scs::core::FacetDescriptions* scs::core::IMetaInterface_stub::getFacetsByName( const scs::core::NameList& _par_names )
{
  CORBA::StaticAny _sa_names( CORBA::_stcseq_string, &_par_names );
  CORBA::StaticAny __res( _marshaller__seq_scs_core_FacetDescription );

  CORBA::StaticRequest __req( this, "getFacetsByName" );
  __req.add_in_arg( &_sa_names );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    _marshaller_scs_core_InvalidName, "IDL:scs/core/InvalidName:1.0",
    0);
  return (scs::core::FacetDescriptions*) __res._retn();
}


#ifndef MICO_CONF_NO_POA

scs::core::FacetDescriptions*
scs::core::IMetaInterface_stub_clp::getFacetsByName( const scs::core::NameList& _par_names )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IMetaInterface * _myserv = POA_scs::core::IMetaInterface::_narrow (_serv);
    if (_myserv) {
      scs::core::FacetDescriptions* __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->getFacetsByName(_par_names);
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return scs::core::IMetaInterface_stub::getFacetsByName(_par_names);
}

#endif // MICO_CONF_NO_POA

scs::core::ReceptacleDescriptions* scs::core::IMetaInterface_stub::getReceptacles()
{
  CORBA::StaticAny __res( _marshaller__seq_scs_core_ReceptacleDescription );

  CORBA::StaticRequest __req( this, "getReceptacles" );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return (scs::core::ReceptacleDescriptions*) __res._retn();
}


#ifndef MICO_CONF_NO_POA

scs::core::ReceptacleDescriptions*
scs::core::IMetaInterface_stub_clp::getReceptacles()
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IMetaInterface * _myserv = POA_scs::core::IMetaInterface::_narrow (_serv);
    if (_myserv) {
      scs::core::ReceptacleDescriptions* __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->getReceptacles();
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return scs::core::IMetaInterface_stub::getReceptacles();
}

#endif // MICO_CONF_NO_POA

scs::core::ReceptacleDescriptions* scs::core::IMetaInterface_stub::getReceptaclesByName( const scs::core::NameList& _par_names )
{
  CORBA::StaticAny _sa_names( CORBA::_stcseq_string, &_par_names );
  CORBA::StaticAny __res( _marshaller__seq_scs_core_ReceptacleDescription );

  CORBA::StaticRequest __req( this, "getReceptaclesByName" );
  __req.add_in_arg( &_sa_names );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    _marshaller_scs_core_InvalidName, "IDL:scs/core/InvalidName:1.0",
    0);
  return (scs::core::ReceptacleDescriptions*) __res._retn();
}


#ifndef MICO_CONF_NO_POA

scs::core::ReceptacleDescriptions*
scs::core::IMetaInterface_stub_clp::getReceptaclesByName( const scs::core::NameList& _par_names )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_scs::core::IMetaInterface * _myserv = POA_scs::core::IMetaInterface::_narrow (_serv);
    if (_myserv) {
      scs::core::ReceptacleDescriptions* __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->getReceptaclesByName(_par_names);
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return scs::core::IMetaInterface_stub::getReceptaclesByName(_par_names);
}

#endif // MICO_CONF_NO_POA

class _Marshaller__seq_scs_core_FacetDescription : public ::CORBA::StaticTypeInfo {
    typedef SequenceTmpl< scs::core::FacetDescription,MICO_TID_DEF> _MICO_T;
  public:
    ~_Marshaller__seq_scs_core_FacetDescription();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller__seq_scs_core_FacetDescription::~_Marshaller__seq_scs_core_FacetDescription()
{
}

::CORBA::StaticValueType _Marshaller__seq_scs_core_FacetDescription::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller__seq_scs_core_FacetDescription::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller__seq_scs_core_FacetDescription::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller__seq_scs_core_FacetDescription::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::ULong len;
  if( !dc.seq_begin( len ) )
    return FALSE;
  ((_MICO_T *) v)->length( len );
  for( ::CORBA::ULong i = 0; i < len; i++ ) {
    if( !_marshaller_scs_core_FacetDescription->demarshal( dc, &(*(_MICO_T*)v)[i] ) )
      return FALSE;
  }
  return dc.seq_end();
}

void _Marshaller__seq_scs_core_FacetDescription::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::ULong len = ((_MICO_T *) v)->length();
  ec.seq_begin( len );
  for( ::CORBA::ULong i = 0; i < len; i++ )
    _marshaller_scs_core_FacetDescription->marshal( ec, &(*(_MICO_T*)v)[i] );
  ec.seq_end();
}

::CORBA::StaticTypeInfo *_marshaller__seq_scs_core_FacetDescription;

class _Marshaller__seq_scs_core_ConnectionDescription : public ::CORBA::StaticTypeInfo {
    typedef SequenceTmpl< scs::core::ConnectionDescription,MICO_TID_DEF> _MICO_T;
  public:
    ~_Marshaller__seq_scs_core_ConnectionDescription();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller__seq_scs_core_ConnectionDescription::~_Marshaller__seq_scs_core_ConnectionDescription()
{
}

::CORBA::StaticValueType _Marshaller__seq_scs_core_ConnectionDescription::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller__seq_scs_core_ConnectionDescription::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller__seq_scs_core_ConnectionDescription::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller__seq_scs_core_ConnectionDescription::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::ULong len;
  if( !dc.seq_begin( len ) )
    return FALSE;
  ((_MICO_T *) v)->length( len );
  for( ::CORBA::ULong i = 0; i < len; i++ ) {
    if( !_marshaller_scs_core_ConnectionDescription->demarshal( dc, &(*(_MICO_T*)v)[i] ) )
      return FALSE;
  }
  return dc.seq_end();
}

void _Marshaller__seq_scs_core_ConnectionDescription::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::ULong len = ((_MICO_T *) v)->length();
  ec.seq_begin( len );
  for( ::CORBA::ULong i = 0; i < len; i++ )
    _marshaller_scs_core_ConnectionDescription->marshal( ec, &(*(_MICO_T*)v)[i] );
  ec.seq_end();
}

::CORBA::StaticTypeInfo *_marshaller__seq_scs_core_ConnectionDescription;

class _Marshaller__seq_scs_core_ReceptacleDescription : public ::CORBA::StaticTypeInfo {
    typedef SequenceTmpl< scs::core::ReceptacleDescription,MICO_TID_DEF> _MICO_T;
  public:
    ~_Marshaller__seq_scs_core_ReceptacleDescription();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller__seq_scs_core_ReceptacleDescription::~_Marshaller__seq_scs_core_ReceptacleDescription()
{
}

::CORBA::StaticValueType _Marshaller__seq_scs_core_ReceptacleDescription::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller__seq_scs_core_ReceptacleDescription::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller__seq_scs_core_ReceptacleDescription::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller__seq_scs_core_ReceptacleDescription::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::ULong len;
  if( !dc.seq_begin( len ) )
    return FALSE;
  ((_MICO_T *) v)->length( len );
  for( ::CORBA::ULong i = 0; i < len; i++ ) {
    if( !_marshaller_scs_core_ReceptacleDescription->demarshal( dc, &(*(_MICO_T*)v)[i] ) )
      return FALSE;
  }
  return dc.seq_end();
}

void _Marshaller__seq_scs_core_ReceptacleDescription::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::ULong len = ((_MICO_T *) v)->length();
  ec.seq_begin( len );
  for( ::CORBA::ULong i = 0; i < len; i++ )
    _marshaller_scs_core_ReceptacleDescription->marshal( ec, &(*(_MICO_T*)v)[i] );
  ec.seq_end();
}

::CORBA::StaticTypeInfo *_marshaller__seq_scs_core_ReceptacleDescription;

class _Marshaller__seq_scs_core_ComponentId : public ::CORBA::StaticTypeInfo {
    typedef SequenceTmpl< scs::core::ComponentId,MICO_TID_DEF> _MICO_T;
  public:
    ~_Marshaller__seq_scs_core_ComponentId();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller__seq_scs_core_ComponentId::~_Marshaller__seq_scs_core_ComponentId()
{
}

::CORBA::StaticValueType _Marshaller__seq_scs_core_ComponentId::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller__seq_scs_core_ComponentId::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller__seq_scs_core_ComponentId::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller__seq_scs_core_ComponentId::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::ULong len;
  if( !dc.seq_begin( len ) )
    return FALSE;
  ((_MICO_T *) v)->length( len );
  for( ::CORBA::ULong i = 0; i < len; i++ ) {
    if( !_marshaller_scs_core_ComponentId->demarshal( dc, &(*(_MICO_T*)v)[i] ) )
      return FALSE;
  }
  return dc.seq_end();
}

void _Marshaller__seq_scs_core_ComponentId::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::ULong len = ((_MICO_T *) v)->length();
  ec.seq_begin( len );
  for( ::CORBA::ULong i = 0; i < len; i++ )
    _marshaller_scs_core_ComponentId->marshal( ec, &(*(_MICO_T*)v)[i] );
  ec.seq_end();
}

::CORBA::StaticTypeInfo *_marshaller__seq_scs_core_ComponentId;

class _Marshaller__seq_scs_core_IComponent : public ::CORBA::StaticTypeInfo {
    typedef IfaceSequenceTmpl< scs::core::IComponent_var,scs::core::IComponent_ptr> _MICO_T;
  public:
    ~_Marshaller__seq_scs_core_IComponent();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller__seq_scs_core_IComponent::~_Marshaller__seq_scs_core_IComponent()
{
}

::CORBA::StaticValueType _Marshaller__seq_scs_core_IComponent::create() const
{
  return (StaticValueType) new _MICO_T;
}

void _Marshaller__seq_scs_core_IComponent::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = *(_MICO_T*) s;
}

void _Marshaller__seq_scs_core_IComponent::free( StaticValueType v ) const
{
  delete (_MICO_T*) v;
}

::CORBA::Boolean _Marshaller__seq_scs_core_IComponent::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::ULong len;
  if( !dc.seq_begin( len ) )
    return FALSE;
  ((_MICO_T *) v)->length( len );
  for( ::CORBA::ULong i = 0; i < len; i++ ) {
    if( !_marshaller_scs_core_IComponent->demarshal( dc, &(*(_MICO_T*)v)[i]._for_demarshal() ) )
      return FALSE;
  }
  return dc.seq_end();
}

void _Marshaller__seq_scs_core_IComponent::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::ULong len = ((_MICO_T *) v)->length();
  ec.seq_begin( len );
  for( ::CORBA::ULong i = 0; i < len; i++ )
    _marshaller_scs_core_IComponent->marshal( ec, &(*(_MICO_T*)v)[i].inout() );
  ec.seq_end();
}

::CORBA::StaticTypeInfo *_marshaller__seq_scs_core_IComponent;

struct __tc_init_SCS {
  __tc_init_SCS()
  {
    _marshaller_scs_core_StartupFailed = new _Marshaller_scs_core_StartupFailed;
    _marshaller_scs_core_ShutdownFailed = new _Marshaller_scs_core_ShutdownFailed;
    _marshaller_scs_core_InvalidName = new _Marshaller_scs_core_InvalidName;
    _marshaller_scs_core_InvalidConnection = new _Marshaller_scs_core_InvalidConnection;
    _marshaller_scs_core_AlreadyConnected = new _Marshaller_scs_core_AlreadyConnected;
    _marshaller_scs_core_ExceededConnectionLimit = new _Marshaller_scs_core_ExceededConnectionLimit;
    _marshaller_scs_core_NoConnection = new _Marshaller_scs_core_NoConnection;
    _marshaller_scs_core_FacetDescription = new _Marshaller_scs_core_FacetDescription;
    _marshaller_scs_core_ConnectionDescription = new _Marshaller_scs_core_ConnectionDescription;
    _marshaller_scs_core_ReceptacleDescription = new _Marshaller_scs_core_ReceptacleDescription;
    _marshaller_scs_core_ComponentId = new _Marshaller_scs_core_ComponentId;
    _marshaller_scs_core_IComponent = new _Marshaller_scs_core_IComponent;
    _marshaller_scs_core_IReceptacles = new _Marshaller_scs_core_IReceptacles;
    _marshaller_scs_core_IMetaInterface = new _Marshaller_scs_core_IMetaInterface;
    _marshaller__seq_scs_core_FacetDescription = new _Marshaller__seq_scs_core_FacetDescription;
    _marshaller__seq_scs_core_ConnectionDescription = new _Marshaller__seq_scs_core_ConnectionDescription;
    _marshaller__seq_scs_core_ReceptacleDescription = new _Marshaller__seq_scs_core_ReceptacleDescription;
    _marshaller__seq_scs_core_ComponentId = new _Marshaller__seq_scs_core_ComponentId;
    _marshaller__seq_scs_core_IComponent = new _Marshaller__seq_scs_core_IComponent;
  }

  ~__tc_init_SCS()
  {
    delete static_cast<_Marshaller_scs_core_StartupFailed*>(_marshaller_scs_core_StartupFailed);
    delete static_cast<_Marshaller_scs_core_ShutdownFailed*>(_marshaller_scs_core_ShutdownFailed);
    delete static_cast<_Marshaller_scs_core_InvalidName*>(_marshaller_scs_core_InvalidName);
    delete static_cast<_Marshaller_scs_core_InvalidConnection*>(_marshaller_scs_core_InvalidConnection);
    delete static_cast<_Marshaller_scs_core_AlreadyConnected*>(_marshaller_scs_core_AlreadyConnected);
    delete static_cast<_Marshaller_scs_core_ExceededConnectionLimit*>(_marshaller_scs_core_ExceededConnectionLimit);
    delete static_cast<_Marshaller_scs_core_NoConnection*>(_marshaller_scs_core_NoConnection);
    delete static_cast<_Marshaller_scs_core_FacetDescription*>(_marshaller_scs_core_FacetDescription);
    delete static_cast<_Marshaller_scs_core_ConnectionDescription*>(_marshaller_scs_core_ConnectionDescription);
    delete static_cast<_Marshaller_scs_core_ReceptacleDescription*>(_marshaller_scs_core_ReceptacleDescription);
    delete static_cast<_Marshaller_scs_core_ComponentId*>(_marshaller_scs_core_ComponentId);
    delete static_cast<_Marshaller_scs_core_IComponent*>(_marshaller_scs_core_IComponent);
    delete static_cast<_Marshaller_scs_core_IReceptacles*>(_marshaller_scs_core_IReceptacles);
    delete static_cast<_Marshaller_scs_core_IMetaInterface*>(_marshaller_scs_core_IMetaInterface);
    delete static_cast<_Marshaller__seq_scs_core_FacetDescription*>(_marshaller__seq_scs_core_FacetDescription);
    delete static_cast<_Marshaller__seq_scs_core_ConnectionDescription*>(_marshaller__seq_scs_core_ConnectionDescription);
    delete static_cast<_Marshaller__seq_scs_core_ReceptacleDescription*>(_marshaller__seq_scs_core_ReceptacleDescription);
    delete static_cast<_Marshaller__seq_scs_core_ComponentId*>(_marshaller__seq_scs_core_ComponentId);
    delete static_cast<_Marshaller__seq_scs_core_IComponent*>(_marshaller__seq_scs_core_IComponent);
  }
};

static __tc_init_SCS __init_SCS;

//--------------------------------------------------------
//  Implementation of skeletons
//--------------------------------------------------------

// PortableServer Skeleton Class for interface scs::core::IComponent
POA_scs::core::IComponent::~IComponent()
{
}

::scs::core::IComponent_ptr
POA_scs::core::IComponent::_this ()
{
  CORBA::Object_var obj = PortableServer::ServantBase::_this();
  return ::scs::core::IComponent::_narrow (obj);
}

CORBA::Boolean
POA_scs::core::IComponent::_is_a (const char * repoid)
{
  if (strcmp (repoid, "IDL:scs/core/IComponent:1.0") == 0) {
    return TRUE;
  }
  return FALSE;
}

CORBA::InterfaceDef_ptr
POA_scs::core::IComponent::_get_interface ()
{
  CORBA::InterfaceDef_ptr ifd = PortableServer::ServantBase::_get_interface ("IDL:scs/core/IComponent:1.0");

  if (CORBA::is_nil (ifd)) {
    mico_throw (CORBA::OBJ_ADAPTER (0, CORBA::COMPLETED_NO));
  }

  return ifd;
}

CORBA::RepositoryId
POA_scs::core::IComponent::_primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr)
{
  return CORBA::string_dup ("IDL:scs/core/IComponent:1.0");
}

CORBA::Object_ptr
POA_scs::core::IComponent::_make_stub (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
{
  return new ::scs::core::IComponent_stub_clp (poa, obj);
}

bool
POA_scs::core::IComponent::dispatch (CORBA::StaticServerRequest_ptr __req)
{
  #ifdef HAVE_EXCEPTIONS
  try {
  #endif
    switch (mico_string_hash (__req->op_name(), 7)) {
    case 1:
      if( strcmp( __req->op_name(), "startup" ) == 0 ) {

        if( !__req->read_args() )
          return true;

        #ifdef HAVE_EXCEPTIONS
        try {
        #endif
          startup();
        #ifdef HAVE_EXCEPTIONS
        } catch( ::scs::core::StartupFailed_catch &_ex ) {
          __req->set_exception( _ex->_clone() );
          __req->write_results();
          return true;
        }
        #endif
        __req->write_results();
        return true;
      }
      if( strcmp( __req->op_name(), "shutdown" ) == 0 ) {

        if( !__req->read_args() )
          return true;

        #ifdef HAVE_EXCEPTIONS
        try {
        #endif
          shutdown();
        #ifdef HAVE_EXCEPTIONS
        } catch( ::scs::core::ShutdownFailed_catch &_ex ) {
          __req->set_exception( _ex->_clone() );
          __req->write_results();
          return true;
        }
        #endif
        __req->write_results();
        return true;
      }
      if( strcmp( __req->op_name(), "getFacet" ) == 0 ) {
        CORBA::String_var _par_facet_interface;
        CORBA::StaticAny _sa_facet_interface( CORBA::_stc_string, &_par_facet_interface._for_demarshal() );

        CORBA::Object_ptr _res;
        CORBA::StaticAny __res( CORBA::_stc_Object, &_res );
        __req->add_in_arg( &_sa_facet_interface );
        __req->set_result( &__res );

        if( !__req->read_args() )
          return true;

        _res = getFacet( _par_facet_interface.inout() );
        __req->write_results();
        CORBA::release( _res );
        return true;
      }
      break;
    case 3:
      if( strcmp( __req->op_name(), "getComponentId" ) == 0 ) {
        ::scs::core::ComponentId* _res;
        CORBA::StaticAny __res( _marshaller_scs_core_ComponentId );
        __req->set_result( &__res );

        if( !__req->read_args() )
          return true;

        _res = getComponentId();
        __res.value( _marshaller_scs_core_ComponentId, _res );
        __req->write_results();
        delete _res;
        return true;
      }
      break;
    case 4:
      if( strcmp( __req->op_name(), "getFacetByName" ) == 0 ) {
        CORBA::String_var _par_facet;
        CORBA::StaticAny _sa_facet( CORBA::_stc_string, &_par_facet._for_demarshal() );

        CORBA::Object_ptr _res;
        CORBA::StaticAny __res( CORBA::_stc_Object, &_res );
        __req->add_in_arg( &_sa_facet );
        __req->set_result( &__res );

        if( !__req->read_args() )
          return true;

        _res = getFacetByName( _par_facet.inout() );
        __req->write_results();
        CORBA::release( _res );
        return true;
      }
      break;
    }
  #ifdef HAVE_EXCEPTIONS
  } catch( CORBA::SystemException_catch &_ex ) {
    __req->set_exception( _ex->_clone() );
    __req->write_results();
    return true;
  } catch( ... ) {
    CORBA::UNKNOWN _ex (CORBA::OMGVMCID | 1, CORBA::COMPLETED_MAYBE);
    __req->set_exception (_ex->_clone());
    __req->write_results ();
    return true;
  }
  #endif

  return false;
}

void
POA_scs::core::IComponent::invoke (CORBA::StaticServerRequest_ptr __req)
{
  if (dispatch (__req)) {
      return;
  }

  CORBA::Exception * ex = 
    new CORBA::BAD_OPERATION (0, CORBA::COMPLETED_NO);
  __req->set_exception (ex);
  __req->write_results();
}


// PortableServer Skeleton Class for interface scs::core::IReceptacles
POA_scs::core::IReceptacles::~IReceptacles()
{
}

::scs::core::IReceptacles_ptr
POA_scs::core::IReceptacles::_this ()
{
  CORBA::Object_var obj = PortableServer::ServantBase::_this();
  return ::scs::core::IReceptacles::_narrow (obj);
}

CORBA::Boolean
POA_scs::core::IReceptacles::_is_a (const char * repoid)
{
  if (strcmp (repoid, "IDL:scs/core/IReceptacles:1.0") == 0) {
    return TRUE;
  }
  return FALSE;
}

CORBA::InterfaceDef_ptr
POA_scs::core::IReceptacles::_get_interface ()
{
  CORBA::InterfaceDef_ptr ifd = PortableServer::ServantBase::_get_interface ("IDL:scs/core/IReceptacles:1.0");

  if (CORBA::is_nil (ifd)) {
    mico_throw (CORBA::OBJ_ADAPTER (0, CORBA::COMPLETED_NO));
  }

  return ifd;
}

CORBA::RepositoryId
POA_scs::core::IReceptacles::_primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr)
{
  return CORBA::string_dup ("IDL:scs/core/IReceptacles:1.0");
}

CORBA::Object_ptr
POA_scs::core::IReceptacles::_make_stub (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
{
  return new ::scs::core::IReceptacles_stub_clp (poa, obj);
}

bool
POA_scs::core::IReceptacles::dispatch (CORBA::StaticServerRequest_ptr __req)
{
  #ifdef HAVE_EXCEPTIONS
  try {
  #endif
    if( strcmp( __req->op_name(), "connect" ) == 0 ) {
      CORBA::String_var _par_receptacle;
      CORBA::StaticAny _sa_receptacle( CORBA::_stc_string, &_par_receptacle._for_demarshal() );
      CORBA::Object_var _par_obj;
      CORBA::StaticAny _sa_obj( CORBA::_stc_Object, &_par_obj._for_demarshal() );

      ::scs::core::ConnectionId _res;
      CORBA::StaticAny __res( CORBA::_stc_ulong, &_res );
      __req->add_in_arg( &_sa_receptacle );
      __req->add_in_arg( &_sa_obj );
      __req->set_result( &__res );

      if( !__req->read_args() )
        return true;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        _res = connect( _par_receptacle.inout(), _par_obj.inout() );
      #ifdef HAVE_EXCEPTIONS
      } catch( ::scs::core::InvalidName_catch &_ex ) {
        __req->set_exception( _ex->_clone() );
        __req->write_results();
        return true;
      } catch( ::scs::core::InvalidConnection_catch &_ex ) {
        __req->set_exception( _ex->_clone() );
        __req->write_results();
        return true;
      } catch( ::scs::core::AlreadyConnected_catch &_ex ) {
        __req->set_exception( _ex->_clone() );
        __req->write_results();
        return true;
      } catch( ::scs::core::ExceededConnectionLimit_catch &_ex ) {
        __req->set_exception( _ex->_clone() );
        __req->write_results();
        return true;
      }
      #endif
      __req->write_results();
      return true;
    }
    if( strcmp( __req->op_name(), "disconnect" ) == 0 ) {
      ::scs::core::ConnectionId _par_id;
      CORBA::StaticAny _sa_id( CORBA::_stc_ulong, &_par_id );

      __req->add_in_arg( &_sa_id );

      if( !__req->read_args() )
        return true;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        disconnect( _par_id );
      #ifdef HAVE_EXCEPTIONS
      } catch( ::scs::core::InvalidConnection_catch &_ex ) {
        __req->set_exception( _ex->_clone() );
        __req->write_results();
        return true;
      } catch( ::scs::core::NoConnection_catch &_ex ) {
        __req->set_exception( _ex->_clone() );
        __req->write_results();
        return true;
      }
      #endif
      __req->write_results();
      return true;
    }
    if( strcmp( __req->op_name(), "getConnections" ) == 0 ) {
      CORBA::String_var _par_receptacle;
      CORBA::StaticAny _sa_receptacle( CORBA::_stc_string, &_par_receptacle._for_demarshal() );

      ::scs::core::ConnectionDescriptions* _res;
      CORBA::StaticAny __res( _marshaller__seq_scs_core_ConnectionDescription );
      __req->add_in_arg( &_sa_receptacle );
      __req->set_result( &__res );

      if( !__req->read_args() )
        return true;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        _res = getConnections( _par_receptacle.inout() );
        __res.value( _marshaller__seq_scs_core_ConnectionDescription, _res );
      #ifdef HAVE_EXCEPTIONS
      } catch( ::scs::core::InvalidName_catch &_ex ) {
        __req->set_exception( _ex->_clone() );
        __req->write_results();
        return true;
      }
      #endif
      __req->write_results();
      delete _res;
      return true;
    }
  #ifdef HAVE_EXCEPTIONS
  } catch( CORBA::SystemException_catch &_ex ) {
    __req->set_exception( _ex->_clone() );
    __req->write_results();
    return true;
  } catch( ... ) {
    CORBA::UNKNOWN _ex (CORBA::OMGVMCID | 1, CORBA::COMPLETED_MAYBE);
    __req->set_exception (_ex->_clone());
    __req->write_results ();
    return true;
  }
  #endif

  return false;
}

void
POA_scs::core::IReceptacles::invoke (CORBA::StaticServerRequest_ptr __req)
{
  if (dispatch (__req)) {
      return;
  }

  CORBA::Exception * ex = 
    new CORBA::BAD_OPERATION (0, CORBA::COMPLETED_NO);
  __req->set_exception (ex);
  __req->write_results();
}


// PortableServer Skeleton Class for interface scs::core::IMetaInterface
POA_scs::core::IMetaInterface::~IMetaInterface()
{
}

::scs::core::IMetaInterface_ptr
POA_scs::core::IMetaInterface::_this ()
{
  CORBA::Object_var obj = PortableServer::ServantBase::_this();
  return ::scs::core::IMetaInterface::_narrow (obj);
}

CORBA::Boolean
POA_scs::core::IMetaInterface::_is_a (const char * repoid)
{
  if (strcmp (repoid, "IDL:scs/core/IMetaInterface:1.0") == 0) {
    return TRUE;
  }
  return FALSE;
}

CORBA::InterfaceDef_ptr
POA_scs::core::IMetaInterface::_get_interface ()
{
  CORBA::InterfaceDef_ptr ifd = PortableServer::ServantBase::_get_interface ("IDL:scs/core/IMetaInterface:1.0");

  if (CORBA::is_nil (ifd)) {
    mico_throw (CORBA::OBJ_ADAPTER (0, CORBA::COMPLETED_NO));
  }

  return ifd;
}

CORBA::RepositoryId
POA_scs::core::IMetaInterface::_primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr)
{
  return CORBA::string_dup ("IDL:scs/core/IMetaInterface:1.0");
}

CORBA::Object_ptr
POA_scs::core::IMetaInterface::_make_stub (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
{
  return new ::scs::core::IMetaInterface_stub_clp (poa, obj);
}

bool
POA_scs::core::IMetaInterface::dispatch (CORBA::StaticServerRequest_ptr __req)
{
  #ifdef HAVE_EXCEPTIONS
  try {
  #endif
    switch (mico_string_hash (__req->op_name(), 7)) {
    case 1:
      if( strcmp( __req->op_name(), "getFacets" ) == 0 ) {
        ::scs::core::FacetDescriptions* _res;
        CORBA::StaticAny __res( _marshaller__seq_scs_core_FacetDescription );
        __req->set_result( &__res );

        if( !__req->read_args() )
          return true;

        _res = getFacets();
        __res.value( _marshaller__seq_scs_core_FacetDescription, _res );
        __req->write_results();
        delete _res;
        return true;
      }
      break;
    case 2:
      if( strcmp( __req->op_name(), "getReceptaclesByName" ) == 0 ) {
        ::scs::core::NameList _par_names;
        CORBA::StaticAny _sa_names( CORBA::_stcseq_string, &_par_names );

        ::scs::core::ReceptacleDescriptions* _res;
        CORBA::StaticAny __res( _marshaller__seq_scs_core_ReceptacleDescription );
        __req->add_in_arg( &_sa_names );
        __req->set_result( &__res );

        if( !__req->read_args() )
          return true;

        #ifdef HAVE_EXCEPTIONS
        try {
        #endif
          _res = getReceptaclesByName( _par_names );
          __res.value( _marshaller__seq_scs_core_ReceptacleDescription, _res );
        #ifdef HAVE_EXCEPTIONS
        } catch( ::scs::core::InvalidName_catch &_ex ) {
          __req->set_exception( _ex->_clone() );
          __req->write_results();
          return true;
        }
        #endif
        __req->write_results();
        delete _res;
        return true;
      }
      break;
    case 4:
      if( strcmp( __req->op_name(), "getFacetsByName" ) == 0 ) {
        ::scs::core::NameList _par_names;
        CORBA::StaticAny _sa_names( CORBA::_stcseq_string, &_par_names );

        ::scs::core::FacetDescriptions* _res;
        CORBA::StaticAny __res( _marshaller__seq_scs_core_FacetDescription );
        __req->add_in_arg( &_sa_names );
        __req->set_result( &__res );

        if( !__req->read_args() )
          return true;

        #ifdef HAVE_EXCEPTIONS
        try {
        #endif
          _res = getFacetsByName( _par_names );
          __res.value( _marshaller__seq_scs_core_FacetDescription, _res );
        #ifdef HAVE_EXCEPTIONS
        } catch( ::scs::core::InvalidName_catch &_ex ) {
          __req->set_exception( _ex->_clone() );
          __req->write_results();
          return true;
        }
        #endif
        __req->write_results();
        delete _res;
        return true;
      }
      if( strcmp( __req->op_name(), "getReceptacles" ) == 0 ) {
        ::scs::core::ReceptacleDescriptions* _res;
        CORBA::StaticAny __res( _marshaller__seq_scs_core_ReceptacleDescription );
        __req->set_result( &__res );

        if( !__req->read_args() )
          return true;

        _res = getReceptacles();
        __res.value( _marshaller__seq_scs_core_ReceptacleDescription, _res );
        __req->write_results();
        delete _res;
        return true;
      }
      break;
    }
  #ifdef HAVE_EXCEPTIONS
  } catch( CORBA::SystemException_catch &_ex ) {
    __req->set_exception( _ex->_clone() );
    __req->write_results();
    return true;
  } catch( ... ) {
    CORBA::UNKNOWN _ex (CORBA::OMGVMCID | 1, CORBA::COMPLETED_MAYBE);
    __req->set_exception (_ex->_clone());
    __req->write_results ();
    return true;
  }
  #endif

  return false;
}

void
POA_scs::core::IMetaInterface::invoke (CORBA::StaticServerRequest_ptr __req)
{
  if (dispatch (__req)) {
      return;
  }

  CORBA::Exception * ex = 
    new CORBA::BAD_OPERATION (0, CORBA::COMPLETED_NO);
  __req->set_exception (ex);
  __req->write_results();
}

