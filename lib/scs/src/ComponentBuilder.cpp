/*
** ComponentBuilder.cpp
*/

#include <scs/core/ComponentBuilder.h>

namespace scs {
  namespace core {
    ComponentBuilder::ComponentBuilder(CORBA::ORB* _orb, PortableServer::POA* _poa) {
      orb = _orb;
      poa = _poa;
    }

    ComponentBuilder::~ComponentBuilder() {
      /* empty */
    }

    IComponentImpl* ComponentBuilder::createComponent(const char* name, CORBA::Octet major_version, \
        CORBA::Octet minor_version, CORBA::Octet patch_version, const char* platform_spec) {
      return  new IComponentImpl(name, major_version, minor_version, \
          patch_version, platform_spec, orb, poa);
    }

    IComponentImpl* ComponentBuilder::createComponent(const char* name, CORBA::Octet major_version, \
        CORBA::Octet minor_version, CORBA::Octet patch_version, const char* platform_spec, \
        const char* facet_name, const char* interface_name, PortableServer::ServantBase* obj) {
      IComponentImpl* IComponent = new IComponentImpl(name, major_version, minor_version, \
          patch_version, platform_spec, orb, poa);
      IComponent->addFacet(facet_name, interface_name, obj);
      return IComponent;
    }
  }
}
