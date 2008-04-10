/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <CORBA.h>
#include <mico/throw.h>

#ifndef __REGISTRY_SERVICE_H__
#define __REGISTRY_SERVICE_H__






namespace openbusidl
{
namespace rs
{

class IRegistryService;
typedef IRegistryService *IRegistryService_ptr;
typedef IRegistryService_ptr IRegistryServiceRef;
typedef ObjVar< IRegistryService > IRegistryService_var;
typedef ObjOut< IRegistryService > IRegistryService_out;

}
}



#include "core.h"
#include "scs.h"



namespace openbusidl
{
namespace rs
{

typedef StringSequenceTmpl<CORBA::String_var> PropertyValue;
typedef TSeqVar< StringSequenceTmpl<CORBA::String_var> > PropertyValue_var;
typedef TSeqOut< StringSequenceTmpl<CORBA::String_var> > PropertyValue_out;

struct Property;
typedef TVarVar< Property > Property_var;
typedef TVarOut< Property > Property_out;


struct Property {
  #ifdef HAVE_TYPEDEF_OVERLOAD
  typedef Property_var _var_type;
  #endif
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  Property();
  ~Property();
  Property( const Property& s );
  Property& operator=( const Property& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS

  CORBA::String_var name;
  PropertyValue value;
};

typedef SequenceTmpl< Property,MICO_TID_DEF> PropertyList;
typedef TSeqVar< SequenceTmpl< Property,MICO_TID_DEF> > PropertyList_var;
typedef TSeqOut< SequenceTmpl< Property,MICO_TID_DEF> > PropertyList_out;

struct ServiceOffer;
typedef TVarVar< ServiceOffer > ServiceOffer_var;
typedef TVarOut< ServiceOffer > ServiceOffer_out;


struct ServiceOffer {
  #ifdef HAVE_TYPEDEF_OVERLOAD
  typedef ServiceOffer_var _var_type;
  #endif
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  ServiceOffer();
  ~ServiceOffer();
  ServiceOffer( const ServiceOffer& s );
  ServiceOffer& operator=( const ServiceOffer& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS

  CORBA::String_var type;
  CORBA::String_var description;
  PropertyList properties;
  ::scs::core::IComponent_var member;
};

typedef SequenceTmpl< ServiceOffer,MICO_TID_DEF> ServiceOfferList;
typedef TSeqVar< SequenceTmpl< ServiceOffer,MICO_TID_DEF> > ServiceOfferList_var;
typedef TSeqOut< SequenceTmpl< ServiceOffer,MICO_TID_DEF> > ServiceOfferList_out;

typedef char* RegistryIdentifier;
typedef CORBA::String_var RegistryIdentifier_var;
typedef CORBA::String_out RegistryIdentifier_out;


/*
 * Base class and common definitions for interface IRegistryService
 */

class IRegistryService : 
  virtual public ::scs::core::IComponent
{
  public:
    virtual ~IRegistryService();

    #ifdef HAVE_TYPEDEF_OVERLOAD
    typedef IRegistryService_ptr _ptr_type;
    typedef IRegistryService_var _var_type;
    #endif

    static IRegistryService_ptr _narrow( CORBA::Object_ptr obj );
    static IRegistryService_ptr _narrow( CORBA::AbstractBase_ptr obj );
    static IRegistryService_ptr _duplicate( IRegistryService_ptr _obj )
    {
      CORBA::Object::_duplicate (_obj);
      return _obj;
    }

    static IRegistryService_ptr _nil()
    {
      return 0;
    }

    virtual void *_narrow_helper( const char *repoid );

    virtual CORBA::Boolean _cxx_register( const ServiceOffer& aServiceOffer, CORBA::String_out identifier ) = 0;
    virtual CORBA::Boolean unregister( const char* identifier ) = 0;
    virtual CORBA::Boolean update( const char* identifier, const PropertyList& newProperties ) = 0;
    virtual ServiceOfferList* find( const char* type, const PropertyList& criteria ) = 0;

  protected:
    IRegistryService() {};
  private:
    IRegistryService( const IRegistryService& );
    void operator=( const IRegistryService& );
};

// Stub for interface IRegistryService
class IRegistryService_stub:
  virtual public IRegistryService,
  virtual public ::scs::core::IComponent_stub
{
  public:
    virtual ~IRegistryService_stub();
    CORBA::Boolean _cxx_register( const ServiceOffer& aServiceOffer, CORBA::String_out identifier );
    CORBA::Boolean unregister( const char* identifier );
    CORBA::Boolean update( const char* identifier, const PropertyList& newProperties );
    ServiceOfferList* find( const char* type, const PropertyList& criteria );

  private:
    void operator=( const IRegistryService_stub& );
};

}
}


#ifndef MICO_CONF_NO_POA

#endif // MICO_CONF_NO_POA

extern CORBA::StaticTypeInfo *_marshaller_openbusidl_rs_Property;

extern CORBA::StaticTypeInfo *_marshaller_openbusidl_rs_ServiceOffer;

extern CORBA::StaticTypeInfo *_marshaller_openbusidl_rs_IRegistryService;

extern CORBA::StaticTypeInfo *_marshaller__seq_openbusidl_rs_Property;

extern CORBA::StaticTypeInfo *_marshaller__seq_openbusidl_rs_ServiceOffer;

#endif
