/*
** ComponentContext.cpp
*/

#include <scs/core/ComponentContextOrbix.h>

namespace scs {
  namespace core {
    ComponentContext::ComponentContext(ComponentBuilder* builder, ComponentId* id) {
      this->builder = builder;
      this->id = *id;
      this->extFacetDescs = new std::map<std::string, ExtendedFacetDescription>();
      this->facetDescs = new std::map<std::string, FacetDescription>();
//      this.receptacleDescs = new std::map<std::string, ReceptacleDescription>();
      this->facets = new std::map<std::string, void*>();
//      this.receptacles = new std::map<std::string, Receptacle&>();
    }

    ComponentContext::~ComponentContext() {
      std::map<std::string, void*>::iterator it;
      for (it = facets->begin(); it != facets->end(); it++) {
        ExtendedFacetDescription desc = this->getExtendedFacetDescs()[it->first];
        // desativa objeto CORBA
        this->builder->getPOA()->deactivate_object(desc.oid);
        // destroi objeto
        desc.destructor(it->second);
        it->second = NULL;
      }
      facets->clear();
      delete facets;
      facetDescs->clear();
      delete facetDescs;
      extFacetDescs->clear();
      delete extFacetDescs;
//      receptacleDescs.clear();
//      delete receptacleDescs;
//      receptacles.clear();
//      delete receptacles;
    }

    ComponentBuilder* ComponentContext::getBuilder() {
      return this->builder;
    }

    ComponentId ComponentContext::getComponentId() {
      return this->id;
    }

    std::map<std::string, void*>& ComponentContext::getFacets() {
      return *(this->facets);
    }

    std::map<std::string, FacetDescription>& ComponentContext::getFacetDescs() {
      return *(this->facetDescs);
    }

    std::map<std::string, ExtendedFacetDescription>& ComponentContext::getExtendedFacetDescs() {
      return *(this->extFacetDescs);
    }

//    std::map<std::string, ReceptacleDescription>& ComponentContext::getReceptacleDescs() {
//      return *(this.receptacleDescs);
//    }

//    std::map<std::string, Receptacle&>& ComponentContext::getReceptacles() {
//      return *(this.receptacles);
//    }

    scs::core::IComponent_var ComponentContext::getIComponent() {
      std::map<std::string, FacetDescription>::const_iterator it;
      it = facetDescs->find(ICOMPONENT_NAME);
      if (it != facetDescs->end()) {
        FacetDescription desc = it->second;
        return scs::core::IComponent::_narrow(desc.facet_ref);
      }
      return NULL;
    }
  }
}
