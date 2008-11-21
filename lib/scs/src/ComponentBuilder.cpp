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

    IComponentImpl* ComponentBuilder::createComponent(const char* name, unsigned long version, const char* facet_name, \
          const char* interface_name, PortableServer::ServantBase* obj)
    {
      IComponentImpl* IComponent = new IComponentImpl(name, version, orb, poa);
      IComponent->addFacet(facet_name, interface_name, obj);
      return IComponent;
    }
  }
}
