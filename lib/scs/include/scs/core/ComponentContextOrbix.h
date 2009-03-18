/*
** ComponentContext.h
*/

#ifndef COMPONENTCONTEXT_H_
#define COMPONENTCONTEXT_H_

#include <string>
#include <map>
#include <stubs/scsS.hh>
#include <scs/core/ComponentBuilderOrbix.h>
#include <scs/core/IComponentOrbix.h>
#include <scs/core/ExtendedFacetDescription.h>

namespace scs {
  namespace core {
    class ComponentBuilder;

    class ComponentContext {
      private:
        ComponentBuilder* builder;
        ComponentId id;
        // facetDescs contain CORBA objects (field facet_ref)
        std::map<std::string, ExtendedFacetDescription>* extFacetDescs;
        std::map<std::string, FacetDescription>* facetDescs;
        // facets contain C++ objects (servants)
        std::map<std::string, void*>* facets;
  //      std::map<std::string, ReceptacleDescription>* receptacleDescs;
  //      std::map<std::string, Receptacle&>* receptacles;
      public:
        ComponentContext(ComponentBuilder* builder, ComponentId* id);
        ~ComponentContext();

        ComponentBuilder* getBuilder();
        ComponentId getComponentId();
        std::map<std::string, void*>& getFacets();
        std::map<std::string, FacetDescription>& getFacetDescs();
        std::map<std::string, ExtendedFacetDescription>& getExtendedFacetDescs();
  //      std::map<std::string, ReceptacleDescription>& getReceptacleDescs();
  //      std::map<std::string, Receptacle&>& getReceptacles();
        scs::core::IComponent_var getIComponent();
      };
  }
}

#endif
