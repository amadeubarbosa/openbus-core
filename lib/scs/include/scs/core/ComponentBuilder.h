/*
** ComponentBuilder.h
*/

#ifndef COMPONENTBUILDER_H_
#define COMPONENTBUILDER_H_
#define ICOMPONENT_NAME "IComponent"
#define IRECEPTACLES_NAME "IReceptacles"
#define IMETAINTERFACE_NAME "IMetaInterface"

#include <string>
#include <vector>
#include <omg/orb.hh>
#include <omg/PortableServer.hh>
#include <scs/core/ComponentContextOrbix.h>
#include <scs/core/ExtendedFacetDescription.h>
#include <scs/core/IComponentOrbix.h>
//#include <scs/core/IReceptacleOrbix.h>
#include <scs/core/IMetaInterfaceOrbix.h>

namespace scs {
  namespace core {
    class ComponentContext;
    class IComponentImpl;

    class ComponentBuilder {
      private:
        CORBA::ORB* orb;
        PortableServer::POA* poa;
      public:
        ComponentBuilder(CORBA::ORB* _orb, PortableServer::POA* _poa);
        ~ComponentBuilder();
        ComponentContext* newComponent(std::vector<ExtendedFacetDescription>& facetExtDescs, ComponentId& id);
        ComponentContext* newFullComponent(std::vector<ExtendedFacetDescription>& facetExtDescs, ComponentId& id);
        void addFacet(ComponentContext& context, ExtendedFacetDescription extDesc);
    };
  }
}

#endif
