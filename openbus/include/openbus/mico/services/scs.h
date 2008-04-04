/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <CORBA.h>
#include <mico/throw.h>

#ifndef __SCS_H__
#define __SCS_H__






namespace scs
{
namespace core
{

class IComponent;
typedef IComponent *IComponent_ptr;
typedef IComponent_ptr IComponentRef;
typedef ObjVar< IComponent > IComponent_var;
typedef ObjOut< IComponent > IComponent_out;

class IReceptacles;
typedef IReceptacles *IReceptacles_ptr;
typedef IReceptacles_ptr IReceptaclesRef;
typedef ObjVar< IReceptacles > IReceptacles_var;
typedef ObjOut< IReceptacles > IReceptacles_out;

class IMetaInterface;
typedef IMetaInterface *IMetaInterface_ptr;
typedef IMetaInterface_ptr IMetaInterfaceRef;
typedef ObjVar< IMetaInterface > IMetaInterface_var;
typedef ObjOut< IMetaInterface > IMetaInterface_out;

}
}






namespace scs
{
namespace core
{

struct StartupFailed : public CORBA::UserException {
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  StartupFailed();
  ~StartupFailed();
  StartupFailed( const StartupFailed& s );
  StartupFailed& operator=( const StartupFailed& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS


  #ifdef HAVE_STD_EH
  StartupFailed *operator->() { return this; }
  StartupFailed& operator*() { return *this; }
  operator StartupFailed*() { return this; }
  #endif // HAVE_STD_EH

  void _throwit() const;
  const char *_repoid() const;
  void _encode( CORBA::DataEncoder &en ) const;
  void _encode_any( CORBA::Any &a ) const;
  CORBA::Exception *_clone() const;
  static StartupFailed *_downcast( CORBA::Exception *ex );
  static const StartupFailed *_downcast( const CORBA::Exception *ex );
};

#ifdef HAVE_STD_EH
typedef StartupFailed StartupFailed_catch;
#else
typedef ExceptVar< StartupFailed > StartupFailed_var;
typedef TVarOut< StartupFailed > StartupFailed_out;
typedef StartupFailed_var StartupFailed_catch;
#endif // HAVE_STD_EH

struct ShutdownFailed : public CORBA::UserException {
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  ShutdownFailed();
  ~ShutdownFailed();
  ShutdownFailed( const ShutdownFailed& s );
  ShutdownFailed& operator=( const ShutdownFailed& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS


  #ifdef HAVE_STD_EH
  ShutdownFailed *operator->() { return this; }
  ShutdownFailed& operator*() { return *this; }
  operator ShutdownFailed*() { return this; }
  #endif // HAVE_STD_EH

  void _throwit() const;
  const char *_repoid() const;
  void _encode( CORBA::DataEncoder &en ) const;
  void _encode_any( CORBA::Any &a ) const;
  CORBA::Exception *_clone() const;
  static ShutdownFailed *_downcast( CORBA::Exception *ex );
  static const ShutdownFailed *_downcast( const CORBA::Exception *ex );
};

#ifdef HAVE_STD_EH
typedef ShutdownFailed ShutdownFailed_catch;
#else
typedef ExceptVar< ShutdownFailed > ShutdownFailed_var;
typedef TVarOut< ShutdownFailed > ShutdownFailed_out;
typedef ShutdownFailed_var ShutdownFailed_catch;
#endif // HAVE_STD_EH

struct InvalidName : public CORBA::UserException {
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  InvalidName();
  ~InvalidName();
  InvalidName( const InvalidName& s );
  InvalidName& operator=( const InvalidName& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS

  #ifndef HAVE_EXPLICIT_STRUCT_OPS
  InvalidName();
  #endif //HAVE_EXPLICIT_STRUCT_OPS
  InvalidName( const char* _m0 );

  #ifdef HAVE_STD_EH
  InvalidName *operator->() { return this; }
  InvalidName& operator*() { return *this; }
  operator InvalidName*() { return this; }
  #endif // HAVE_STD_EH

  void _throwit() const;
  const char *_repoid() const;
  void _encode( CORBA::DataEncoder &en ) const;
  void _encode_any( CORBA::Any &a ) const;
  CORBA::Exception *_clone() const;
  static InvalidName *_downcast( CORBA::Exception *ex );
  static const InvalidName *_downcast( const CORBA::Exception *ex );
  CORBA::String_var name;
};

#ifdef HAVE_STD_EH
typedef InvalidName InvalidName_catch;
#else
typedef ExceptVar< InvalidName > InvalidName_var;
typedef TVarOut< InvalidName > InvalidName_out;
typedef InvalidName_var InvalidName_catch;
#endif // HAVE_STD_EH

struct InvalidConnection : public CORBA::UserException {
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  InvalidConnection();
  ~InvalidConnection();
  InvalidConnection( const InvalidConnection& s );
  InvalidConnection& operator=( const InvalidConnection& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS


  #ifdef HAVE_STD_EH
  InvalidConnection *operator->() { return this; }
  InvalidConnection& operator*() { return *this; }
  operator InvalidConnection*() { return this; }
  #endif // HAVE_STD_EH

  void _throwit() const;
  const char *_repoid() const;
  void _encode( CORBA::DataEncoder &en ) const;
  void _encode_any( CORBA::Any &a ) const;
  CORBA::Exception *_clone() const;
  static InvalidConnection *_downcast( CORBA::Exception *ex );
  static const InvalidConnection *_downcast( const CORBA::Exception *ex );
};

#ifdef HAVE_STD_EH
typedef InvalidConnection InvalidConnection_catch;
#else
typedef ExceptVar< InvalidConnection > InvalidConnection_var;
typedef TVarOut< InvalidConnection > InvalidConnection_out;
typedef InvalidConnection_var InvalidConnection_catch;
#endif // HAVE_STD_EH

struct AlreadyConnected : public CORBA::UserException {
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  AlreadyConnected();
  ~AlreadyConnected();
  AlreadyConnected( const AlreadyConnected& s );
  AlreadyConnected& operator=( const AlreadyConnected& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS


  #ifdef HAVE_STD_EH
  AlreadyConnected *operator->() { return this; }
  AlreadyConnected& operator*() { return *this; }
  operator AlreadyConnected*() { return this; }
  #endif // HAVE_STD_EH

  void _throwit() const;
  const char *_repoid() const;
  void _encode( CORBA::DataEncoder &en ) const;
  void _encode_any( CORBA::Any &a ) const;
  CORBA::Exception *_clone() const;
  static AlreadyConnected *_downcast( CORBA::Exception *ex );
  static const AlreadyConnected *_downcast( const CORBA::Exception *ex );
};

#ifdef HAVE_STD_EH
typedef AlreadyConnected AlreadyConnected_catch;
#else
typedef ExceptVar< AlreadyConnected > AlreadyConnected_var;
typedef TVarOut< AlreadyConnected > AlreadyConnected_out;
typedef AlreadyConnected_var AlreadyConnected_catch;
#endif // HAVE_STD_EH

struct ExceededConnectionLimit : public CORBA::UserException {
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  ExceededConnectionLimit();
  ~ExceededConnectionLimit();
  ExceededConnectionLimit( const ExceededConnectionLimit& s );
  ExceededConnectionLimit& operator=( const ExceededConnectionLimit& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS


  #ifdef HAVE_STD_EH
  ExceededConnectionLimit *operator->() { return this; }
  ExceededConnectionLimit& operator*() { return *this; }
  operator ExceededConnectionLimit*() { return this; }
  #endif // HAVE_STD_EH

  void _throwit() const;
  const char *_repoid() const;
  void _encode( CORBA::DataEncoder &en ) const;
  void _encode_any( CORBA::Any &a ) const;
  CORBA::Exception *_clone() const;
  static ExceededConnectionLimit *_downcast( CORBA::Exception *ex );
  static const ExceededConnectionLimit *_downcast( const CORBA::Exception *ex );
};

#ifdef HAVE_STD_EH
typedef ExceededConnectionLimit ExceededConnectionLimit_catch;
#else
typedef ExceptVar< ExceededConnectionLimit > ExceededConnectionLimit_var;
typedef TVarOut< ExceededConnectionLimit > ExceededConnectionLimit_out;
typedef ExceededConnectionLimit_var ExceededConnectionLimit_catch;
#endif // HAVE_STD_EH

struct NoConnection : public CORBA::UserException {
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  NoConnection();
  ~NoConnection();
  NoConnection( const NoConnection& s );
  NoConnection& operator=( const NoConnection& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS


  #ifdef HAVE_STD_EH
  NoConnection *operator->() { return this; }
  NoConnection& operator*() { return *this; }
  operator NoConnection*() { return this; }
  #endif // HAVE_STD_EH

  void _throwit() const;
  const char *_repoid() const;
  void _encode( CORBA::DataEncoder &en ) const;
  void _encode_any( CORBA::Any &a ) const;
  CORBA::Exception *_clone() const;
  static NoConnection *_downcast( CORBA::Exception *ex );
  static const NoConnection *_downcast( const CORBA::Exception *ex );
};

#ifdef HAVE_STD_EH
typedef NoConnection NoConnection_catch;
#else
typedef ExceptVar< NoConnection > NoConnection_var;
typedef TVarOut< NoConnection > NoConnection_out;
typedef NoConnection_var NoConnection_catch;
#endif // HAVE_STD_EH

typedef CORBA::ULong ConnectionId;
typedef ConnectionId& ConnectionId_out;
typedef StringSequenceTmpl<CORBA::String_var> NameList;
typedef TSeqVar< StringSequenceTmpl<CORBA::String_var> > NameList_var;
typedef TSeqOut< StringSequenceTmpl<CORBA::String_var> > NameList_out;

struct FacetDescription;
typedef TVarVar< FacetDescription > FacetDescription_var;
typedef TVarOut< FacetDescription > FacetDescription_out;


struct FacetDescription {
  #ifdef HAVE_TYPEDEF_OVERLOAD
  typedef FacetDescription_var _var_type;
  #endif
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  FacetDescription();
  ~FacetDescription();
  FacetDescription( const FacetDescription& s );
  FacetDescription& operator=( const FacetDescription& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS

  CORBA::String_var name;
  CORBA::String_var interface_name;
  CORBA::Object_var facet_ref;
};

typedef SequenceTmpl< FacetDescription,MICO_TID_DEF> FacetDescriptions;
typedef TSeqVar< SequenceTmpl< FacetDescription,MICO_TID_DEF> > FacetDescriptions_var;
typedef TSeqOut< SequenceTmpl< FacetDescription,MICO_TID_DEF> > FacetDescriptions_out;

struct ConnectionDescription;
typedef TVarVar< ConnectionDescription > ConnectionDescription_var;
typedef TVarOut< ConnectionDescription > ConnectionDescription_out;


struct ConnectionDescription {
  #ifdef HAVE_TYPEDEF_OVERLOAD
  typedef ConnectionDescription_var _var_type;
  #endif
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  ConnectionDescription();
  ~ConnectionDescription();
  ConnectionDescription( const ConnectionDescription& s );
  ConnectionDescription& operator=( const ConnectionDescription& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS

  ConnectionId id;
  CORBA::Object_var objref;
};

typedef SequenceTmpl< ConnectionDescription,MICO_TID_DEF> ConnectionDescriptions;
typedef TSeqVar< SequenceTmpl< ConnectionDescription,MICO_TID_DEF> > ConnectionDescriptions_var;
typedef TSeqOut< SequenceTmpl< ConnectionDescription,MICO_TID_DEF> > ConnectionDescriptions_out;

struct ReceptacleDescription;
typedef TVarVar< ReceptacleDescription > ReceptacleDescription_var;
typedef TVarOut< ReceptacleDescription > ReceptacleDescription_out;


struct ReceptacleDescription {
  #ifdef HAVE_TYPEDEF_OVERLOAD
  typedef ReceptacleDescription_var _var_type;
  #endif
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  ReceptacleDescription();
  ~ReceptacleDescription();
  ReceptacleDescription( const ReceptacleDescription& s );
  ReceptacleDescription& operator=( const ReceptacleDescription& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS

  CORBA::String_var name;
  CORBA::String_var interface_name;
  CORBA::Boolean is_multiplex;
  ConnectionDescriptions connections;
};

typedef SequenceTmpl< ReceptacleDescription,MICO_TID_DEF> ReceptacleDescriptions;
typedef TSeqVar< SequenceTmpl< ReceptacleDescription,MICO_TID_DEF> > ReceptacleDescriptions_var;
typedef TSeqOut< SequenceTmpl< ReceptacleDescription,MICO_TID_DEF> > ReceptacleDescriptions_out;

struct ComponentId;
typedef TVarVar< ComponentId > ComponentId_var;
typedef TVarOut< ComponentId > ComponentId_out;


struct ComponentId {
  #ifdef HAVE_TYPEDEF_OVERLOAD
  typedef ComponentId_var _var_type;
  #endif
  #ifdef HAVE_EXPLICIT_STRUCT_OPS
  ComponentId();
  ~ComponentId();
  ComponentId( const ComponentId& s );
  ComponentId& operator=( const ComponentId& s );
  #endif //HAVE_EXPLICIT_STRUCT_OPS

  CORBA::String_var name;
  CORBA::ULong version;
};

typedef SequenceTmpl< ComponentId,MICO_TID_DEF> ComponentIdSeq;
typedef TSeqVar< SequenceTmpl< ComponentId,MICO_TID_DEF> > ComponentIdSeq_var;
typedef TSeqOut< SequenceTmpl< ComponentId,MICO_TID_DEF> > ComponentIdSeq_out;


/*
 * Base class and common definitions for interface IComponent
 */

class IComponent : 
  virtual public CORBA::Object
{
  public:
    virtual ~IComponent();

    #ifdef HAVE_TYPEDEF_OVERLOAD
    typedef IComponent_ptr _ptr_type;
    typedef IComponent_var _var_type;
    #endif

    static IComponent_ptr _narrow( CORBA::Object_ptr obj );
    static IComponent_ptr _narrow( CORBA::AbstractBase_ptr obj );
    static IComponent_ptr _duplicate( IComponent_ptr _obj )
    {
      CORBA::Object::_duplicate (_obj);
      return _obj;
    }

    static IComponent_ptr _nil()
    {
      return 0;
    }

    virtual void *_narrow_helper( const char *repoid );

    virtual void startup() = 0;
    virtual void shutdown() = 0;
    virtual CORBA::Object_ptr getFacet( const char* facet_interface ) = 0;
    virtual CORBA::Object_ptr getFacetByName( const char* facet ) = 0;
    virtual ComponentId* getComponentId() = 0;

  protected:
    IComponent() {};
  private:
    IComponent( const IComponent& );
    void operator=( const IComponent& );
};

// Stub for interface IComponent
class IComponent_stub:
  virtual public IComponent
{
  public:
    virtual ~IComponent_stub();
    void startup();
    void shutdown();
    CORBA::Object_ptr getFacet( const char* facet_interface );
    CORBA::Object_ptr getFacetByName( const char* facet );
    ComponentId* getComponentId();

  private:
    void operator=( const IComponent_stub& );
};

#ifndef MICO_CONF_NO_POA

class IComponent_stub_clp :
  virtual public IComponent_stub,
  virtual public PortableServer::StubBase
{
  public:
    IComponent_stub_clp (PortableServer::POA_ptr, CORBA::Object_ptr);
    virtual ~IComponent_stub_clp ();
    void startup();
    void shutdown();
    CORBA::Object_ptr getFacet( const char* facet_interface );
    CORBA::Object_ptr getFacetByName( const char* facet );
    ComponentId* getComponentId();

  protected:
    IComponent_stub_clp ();
  private:
    void operator=( const IComponent_stub_clp & );
};

#endif // MICO_CONF_NO_POA

typedef IfaceSequenceTmpl< IComponent_var,IComponent_ptr> IComponentSeq;
typedef TSeqVar< IfaceSequenceTmpl< IComponent_var,IComponent_ptr> > IComponentSeq_var;
typedef TSeqOut< IfaceSequenceTmpl< IComponent_var,IComponent_ptr> > IComponentSeq_out;


/*
 * Base class and common definitions for interface IReceptacles
 */

class IReceptacles : 
  virtual public CORBA::Object
{
  public:
    virtual ~IReceptacles();

    #ifdef HAVE_TYPEDEF_OVERLOAD
    typedef IReceptacles_ptr _ptr_type;
    typedef IReceptacles_var _var_type;
    #endif

    static IReceptacles_ptr _narrow( CORBA::Object_ptr obj );
    static IReceptacles_ptr _narrow( CORBA::AbstractBase_ptr obj );
    static IReceptacles_ptr _duplicate( IReceptacles_ptr _obj )
    {
      CORBA::Object::_duplicate (_obj);
      return _obj;
    }

    static IReceptacles_ptr _nil()
    {
      return 0;
    }

    virtual void *_narrow_helper( const char *repoid );

    virtual ConnectionId connect( const char* receptacle, CORBA::Object_ptr obj ) = 0;
    virtual void disconnect( ConnectionId id ) = 0;
    virtual ConnectionDescriptions* getConnections( const char* receptacle ) = 0;

  protected:
    IReceptacles() {};
  private:
    IReceptacles( const IReceptacles& );
    void operator=( const IReceptacles& );
};

// Stub for interface IReceptacles
class IReceptacles_stub:
  virtual public IReceptacles
{
  public:
    virtual ~IReceptacles_stub();
    ConnectionId connect( const char* receptacle, CORBA::Object_ptr obj );
    void disconnect( ConnectionId id );
    ConnectionDescriptions* getConnections( const char* receptacle );

  private:
    void operator=( const IReceptacles_stub& );
};

#ifndef MICO_CONF_NO_POA

class IReceptacles_stub_clp :
  virtual public IReceptacles_stub,
  virtual public PortableServer::StubBase
{
  public:
    IReceptacles_stub_clp (PortableServer::POA_ptr, CORBA::Object_ptr);
    virtual ~IReceptacles_stub_clp ();
    ConnectionId connect( const char* receptacle, CORBA::Object_ptr obj );
    void disconnect( ConnectionId id );
    ConnectionDescriptions* getConnections( const char* receptacle );

  protected:
    IReceptacles_stub_clp ();
  private:
    void operator=( const IReceptacles_stub_clp & );
};

#endif // MICO_CONF_NO_POA


/*
 * Base class and common definitions for interface IMetaInterface
 */

class IMetaInterface : 
  virtual public CORBA::Object
{
  public:
    virtual ~IMetaInterface();

    #ifdef HAVE_TYPEDEF_OVERLOAD
    typedef IMetaInterface_ptr _ptr_type;
    typedef IMetaInterface_var _var_type;
    #endif

    static IMetaInterface_ptr _narrow( CORBA::Object_ptr obj );
    static IMetaInterface_ptr _narrow( CORBA::AbstractBase_ptr obj );
    static IMetaInterface_ptr _duplicate( IMetaInterface_ptr _obj )
    {
      CORBA::Object::_duplicate (_obj);
      return _obj;
    }

    static IMetaInterface_ptr _nil()
    {
      return 0;
    }

    virtual void *_narrow_helper( const char *repoid );

    virtual FacetDescriptions* getFacets() = 0;
    virtual FacetDescriptions* getFacetsByName( const NameList& names ) = 0;
    virtual ReceptacleDescriptions* getReceptacles() = 0;
    virtual ReceptacleDescriptions* getReceptaclesByName( const NameList& names ) = 0;

  protected:
    IMetaInterface() {};
  private:
    IMetaInterface( const IMetaInterface& );
    void operator=( const IMetaInterface& );
};

// Stub for interface IMetaInterface
class IMetaInterface_stub:
  virtual public IMetaInterface
{
  public:
    virtual ~IMetaInterface_stub();
    FacetDescriptions* getFacets();
    FacetDescriptions* getFacetsByName( const NameList& names );
    ReceptacleDescriptions* getReceptacles();
    ReceptacleDescriptions* getReceptaclesByName( const NameList& names );

  private:
    void operator=( const IMetaInterface_stub& );
};

#ifndef MICO_CONF_NO_POA

class IMetaInterface_stub_clp :
  virtual public IMetaInterface_stub,
  virtual public PortableServer::StubBase
{
  public:
    IMetaInterface_stub_clp (PortableServer::POA_ptr, CORBA::Object_ptr);
    virtual ~IMetaInterface_stub_clp ();
    FacetDescriptions* getFacets();
    FacetDescriptions* getFacetsByName( const NameList& names );
    ReceptacleDescriptions* getReceptacles();
    ReceptacleDescriptions* getReceptaclesByName( const NameList& names );

  protected:
    IMetaInterface_stub_clp ();
  private:
    void operator=( const IMetaInterface_stub_clp & );
};

#endif // MICO_CONF_NO_POA

}
}


#ifndef MICO_CONF_NO_POA



namespace POA_scs
{
namespace core
{

class IComponent : virtual public PortableServer::StaticImplementation
{
  public:
    virtual ~IComponent ();
    scs::core::IComponent_ptr _this ();
    bool dispatch (CORBA::StaticServerRequest_ptr);
    virtual void invoke (CORBA::StaticServerRequest_ptr);
    virtual CORBA::Boolean _is_a (const char *);
    virtual CORBA::InterfaceDef_ptr _get_interface ();
    virtual CORBA::RepositoryId _primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr);

    virtual void * _narrow_helper (const char *);
    static IComponent * _narrow (PortableServer::Servant);
    virtual CORBA::Object_ptr _make_stub (PortableServer::POA_ptr, CORBA::Object_ptr);

    virtual void startup() = 0;
    virtual void shutdown() = 0;
    virtual CORBA::Object_ptr getFacet( const char* facet_interface ) = 0;
    virtual CORBA::Object_ptr getFacetByName( const char* facet ) = 0;
    virtual ::scs::core::ComponentId* getComponentId() = 0;

  protected:
    IComponent () {};

  private:
    IComponent (const IComponent &);
    void operator= (const IComponent &);
};

class IReceptacles : virtual public PortableServer::StaticImplementation
{
  public:
    virtual ~IReceptacles ();
    scs::core::IReceptacles_ptr _this ();
    bool dispatch (CORBA::StaticServerRequest_ptr);
    virtual void invoke (CORBA::StaticServerRequest_ptr);
    virtual CORBA::Boolean _is_a (const char *);
    virtual CORBA::InterfaceDef_ptr _get_interface ();
    virtual CORBA::RepositoryId _primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr);

    virtual void * _narrow_helper (const char *);
    static IReceptacles * _narrow (PortableServer::Servant);
    virtual CORBA::Object_ptr _make_stub (PortableServer::POA_ptr, CORBA::Object_ptr);

    virtual ::scs::core::ConnectionId connect( const char* receptacle, CORBA::Object_ptr obj ) = 0;
    virtual void disconnect( ::scs::core::ConnectionId id ) = 0;
    virtual ::scs::core::ConnectionDescriptions* getConnections( const char* receptacle ) = 0;

  protected:
    IReceptacles () {};

  private:
    IReceptacles (const IReceptacles &);
    void operator= (const IReceptacles &);
};

class IMetaInterface : virtual public PortableServer::StaticImplementation
{
  public:
    virtual ~IMetaInterface ();
    scs::core::IMetaInterface_ptr _this ();
    bool dispatch (CORBA::StaticServerRequest_ptr);
    virtual void invoke (CORBA::StaticServerRequest_ptr);
    virtual CORBA::Boolean _is_a (const char *);
    virtual CORBA::InterfaceDef_ptr _get_interface ();
    virtual CORBA::RepositoryId _primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr);

    virtual void * _narrow_helper (const char *);
    static IMetaInterface * _narrow (PortableServer::Servant);
    virtual CORBA::Object_ptr _make_stub (PortableServer::POA_ptr, CORBA::Object_ptr);

    virtual ::scs::core::FacetDescriptions* getFacets() = 0;
    virtual ::scs::core::FacetDescriptions* getFacetsByName( const ::scs::core::NameList& names ) = 0;
    virtual ::scs::core::ReceptacleDescriptions* getReceptacles() = 0;
    virtual ::scs::core::ReceptacleDescriptions* getReceptaclesByName( const ::scs::core::NameList& names ) = 0;

  protected:
    IMetaInterface () {};

  private:
    IMetaInterface (const IMetaInterface &);
    void operator= (const IMetaInterface &);
};

}
}


#endif // MICO_CONF_NO_POA

extern CORBA::StaticTypeInfo *_marshaller_scs_core_StartupFailed;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_ShutdownFailed;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_InvalidName;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_InvalidConnection;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_AlreadyConnected;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_ExceededConnectionLimit;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_NoConnection;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_FacetDescription;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_ConnectionDescription;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_ReceptacleDescription;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_ComponentId;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_IComponent;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_IReceptacles;

extern CORBA::StaticTypeInfo *_marshaller_scs_core_IMetaInterface;

extern CORBA::StaticTypeInfo *_marshaller__seq_scs_core_FacetDescription;

extern CORBA::StaticTypeInfo *_marshaller__seq_scs_core_ConnectionDescription;

extern CORBA::StaticTypeInfo *_marshaller__seq_scs_core_ReceptacleDescription;

extern CORBA::StaticTypeInfo *_marshaller__seq_scs_core_ComponentId;

extern CORBA::StaticTypeInfo *_marshaller__seq_scs_core_IComponent;

#endif
