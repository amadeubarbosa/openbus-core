/*
** mico/scs/core/IComponentImpl.cpp
*/

#include <openbus/mico/scs/core/IComponentImpl.h>

#ifdef VERBOSE
using namespace std ;
#endif

namespace scs {
  namespace core {
    IComponentImpl::IComponentImpl( const char* name, unsigned long version, \
                                    CORBA::ORB_ptr orb, PortableServer::POA_ptr poa )
    {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::IComponentImpl() BEGIN]" << endl ;
    #endif
      _orb = orb ;
      _poa = poa ;
      componentId = new ComponentId ;
      componentId->name = name ;
      componentId->version = version ;
    /* Falta adicionar faceta do IMetaInterface ... */
    #ifdef VERBOSE
      cout << "[IComponentImpl::IComponentImpl() BEGIN]" << endl ;
    #endif
    }

    IComponentImpl::~IComponentImpl() {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::~IComponentImpl() BEGIN]" << endl ;
    #endif
    #ifdef VERBOSE
      cout << "[IComponentImpl::~IComponentImpl() END]" << endl ;
    #endif
    }

    void IComponentImpl::addFacet( const char* name, const char* interface_name, \
         PortableServer::ServantBase* obj )
    {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::addFacet() BEGIN]" << endl ;
    #endif
      PortableServer::ObjectId_var oid = _poa->activate_object( obj ) ;
      CORBA::Object_var ref = _poa->id_to_reference( oid.in() ) ;
      FacetDescription_var facet = new FacetDescription ;
      facet->name = name ;
      facet->interface_name = interface_name ;
      facet->facet_ref = ref ;
      facets[ name ] = *facet ;
    #ifdef VERBOSE
      CORBA::String_var str = _orb->object_to_string( ref.in() ) ;
      cout << "\t[IOR:]" << str.in() << endl ;
      cout << "\t[facet.name] = " << name << endl ;
      cout << "\t[facet.interface_name] = " << interface_name << endl ;
    #endif
    #ifdef VERBOSE
      cout << "[IComponentImpl::addFacet() BEGIN]" << endl ;
    #endif
    }

    void IComponentImpl::startup() {}
    void IComponentImpl::shutdown() {}
  /**/

  /*OK*/
    CORBA::Object_ptr IComponentImpl::getFacet( const char* facet_interface ) {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::getFacet() BEGIN]" << endl ;
    #endif
      CORBA::Object_var o = new CORBA::Object() ;
      FacetDescription* f = NULL ;
      for ( it = facets.begin() ; it != facets.end(); it++ ) {
        f = &(*it).second ;
        if (strcmp(f->interface_name, facet_interface) == 0) {
        #ifdef VERBOSE
          cout << "\t[Faceta de interface '" << facet_interface << "' encontrada]" << endl ;
        #endif
          o = f->facet_ref ;
        }
      }
    #ifdef VERBOSE
      cout << "[IComponentImpl::getFacet() END]" << endl ;
    #endif
      return o._retn() ;
    }

  /*OK*/
    CORBA::Object_ptr IComponentImpl::getFacetByName( const char* facet ) {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::getFacetByName() BEGIN]" << endl ;
    #endif
      FacetDescription f ;
      if ( facets.find( facet ) == facets.end() ) {
      #ifdef VERBOSE
        cout << "\t[Faceta de nome '" << facet << "' encontrada]" << endl ;
        cout << "[IComponentImpl::getFacetByName() END]" << endl ;
      #endif
        return facets[ facet ].facet_ref ;
      }
      #ifdef VERBOSE
        cout << "\t[Faceta de nome '" << facet << "' N�O encontrada]" << endl ;
        cout << "[IComponentImpl::getFacetByName() END]" << endl ;
      #endif
      return NULL ;
    }

  /*OK*/
    ComponentId* IComponentImpl::getComponentId() {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::getComponentId() BEGIN]" << endl ;
    #endif
      ComponentId_var cId = new ComponentId ;
      cId = componentId ;
    #ifdef VERBOSE
      cout << "\t[componentID.name: " << cId->name.in() << "]" << endl ;
      cout << "\t[componentID.version: " << cId->version << "]" << endl ;
      cout << "[IComponentImpl::getComponentId() END]" << endl ;
    #endif
      return cId._retn() ;
    }
  }
}
