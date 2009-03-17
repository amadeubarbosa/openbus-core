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
      extFacetDescs->clear();
      delete extFacetDescs;
      facetDescs->clear();
      delete facetDescs;
      facets->clear();
      delete facets;
//      receptacleDescs.clear();
//      delete receptacleDescs;
//      receptacles.clear();
//      delete receptacles;
    }

/*
    ComponentContext& ComponentContext::operator=(const ComponentContext& ct) {
      if (this != &ct) {
        if (NULL == this.extFacetDescs)
          this.extFacetDescs = new std::map<std::string, ExtendedFacetDescription>();
        else
          this.extFacetDescs.clear();
        if (NULL == this.facetDescs)
          this.facetDescs = new std::map<std::string, FacetDescription>();
        else
          this.facetDescs.clear();
        if (NULL == this.facets)
          this.facets = new std::map<std::string, void*>();
        else
          this.facets.clear();
        //      this.receptacleDescs = new std::map<std::string, ReceptacleDescription>();
        //      this.receptacles = new std::map<std::string, Receptacle&>();
        // copia dados
        this.builder = ct.builder;
        this.id = ct.id;
        ...
      }

      return *this;
    }
*/

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
