/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <hello.h>


using namespace std;

//--------------------------------------------------------
//  Implementation of stubs
//--------------------------------------------------------

/*
 * Base interface for class Hello
 */

Hello::~Hello()
{
}

void *
Hello::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:Hello:1.0" ) == 0 )
    return (void *)this;
  return NULL;
}

Hello_ptr
Hello::_narrow( CORBA::Object_ptr _obj )
{
  Hello_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:Hello:1.0" )))
      return _duplicate( (Hello_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:Hello:1.0") || _obj->_is_a_remote ("IDL:Hello:1.0")) {
      _o = new Hello_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

Hello_ptr
Hello::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

class _Marshaller_Hello : public ::CORBA::StaticTypeInfo {
    typedef Hello_ptr _MICO_T;
  public:
    ~_Marshaller_Hello();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_Hello::~_Marshaller_Hello()
{
}

::CORBA::StaticValueType _Marshaller_Hello::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_Hello::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::Hello::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_Hello::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_Hello::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_Hello::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::Hello::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_Hello::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::StaticTypeInfo *_marshaller_Hello;


/*
 * Stub interface for class Hello
 */

Hello_stub::~Hello_stub()
{
}

#ifndef MICO_CONF_NO_POA

void *
POA_Hello::_narrow_helper (const char * repoid)
{
  if (strcmp (repoid, "IDL:Hello:1.0") == 0) {
    return (void *) this;
  }
  return NULL;
}

POA_Hello *
POA_Hello::_narrow (PortableServer::Servant serv) 
{
  void * p;
  if ((p = serv->_narrow_helper ("IDL:Hello:1.0")) != NULL) {
    serv->_add_ref ();
    return (POA_Hello *) p;
  }
  return NULL;
}

Hello_stub_clp::Hello_stub_clp ()
{
}

Hello_stub_clp::Hello_stub_clp (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
  : CORBA::Object(*obj), PortableServer::StubBase(poa)
{
}

Hello_stub_clp::~Hello_stub_clp ()
{
}

#endif // MICO_CONF_NO_POA

void Hello_stub::sayHello()
{
  CORBA::StaticRequest __req( this, "sayHello" );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
}


#ifndef MICO_CONF_NO_POA

void
Hello_stub_clp::sayHello()
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_Hello * _myserv = POA_Hello::_narrow (_serv);
    if (_myserv) {
      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        _myserv->sayHello();
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

  Hello_stub::sayHello();
}

#endif // MICO_CONF_NO_POA

struct __tc_init_HELLO {
  __tc_init_HELLO()
  {
    _marshaller_Hello = new _Marshaller_Hello;
  }

  ~__tc_init_HELLO()
  {
    delete static_cast<_Marshaller_Hello*>(_marshaller_Hello);
  }
};

static __tc_init_HELLO __init_HELLO;

//--------------------------------------------------------
//  Implementation of skeletons
//--------------------------------------------------------

// PortableServer Skeleton Class for interface Hello
POA_Hello::~POA_Hello()
{
}

::Hello_ptr
POA_Hello::_this ()
{
  CORBA::Object_var obj = PortableServer::ServantBase::_this();
  return ::Hello::_narrow (obj);
}

CORBA::Boolean
POA_Hello::_is_a (const char * repoid)
{
  if (strcmp (repoid, "IDL:Hello:1.0") == 0) {
    return TRUE;
  }
  return FALSE;
}

CORBA::InterfaceDef_ptr
POA_Hello::_get_interface ()
{
  CORBA::InterfaceDef_ptr ifd = PortableServer::ServantBase::_get_interface ("IDL:Hello:1.0");

  if (CORBA::is_nil (ifd)) {
    mico_throw (CORBA::OBJ_ADAPTER (0, CORBA::COMPLETED_NO));
  }

  return ifd;
}

CORBA::RepositoryId
POA_Hello::_primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr)
{
  return CORBA::string_dup ("IDL:Hello:1.0");
}

CORBA::Object_ptr
POA_Hello::_make_stub (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
{
  return new ::Hello_stub_clp (poa, obj);
}

bool
POA_Hello::dispatch (CORBA::StaticServerRequest_ptr __req)
{
  #ifdef HAVE_EXCEPTIONS
  try {
  #endif
    if( strcmp( __req->op_name(), "sayHello" ) == 0 ) {

      if( !__req->read_args() )
        return true;

      sayHello();
      __req->write_results();
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
POA_Hello::invoke (CORBA::StaticServerRequest_ptr __req)
{
  if (dispatch (__req)) {
      return;
  }

  CORBA::Exception * ex = 
    new CORBA::BAD_OPERATION (0, CORBA::COMPLETED_NO);
  __req->set_exception (ex);
  __req->write_results();
}

