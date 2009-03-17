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
    }

    void ComponentBuilder::addFacet(ComponentContext& context, ExtendedFacetDescription extDesc)
    {
    #ifdef VERBOSE
      std::cout << "\n\n[ComponentBuilder::addFacet() BEGIN]" << std::endl;
    #endif
      // copia dados para as novas descricoes e cria servant
      PortableServer::ServantBase* facet = (PortableServer::ServantBase*) extDesc.instantiator(&context);
      FacetDescription desc;
      desc.name = extDesc.name.c_str();
      desc.interface_name = extDesc.interface_name.c_str();
      PortableServer::ObjectId_var oid = poa->activate_object(facet);
      CORBA::Object_var ref = poa->id_to_reference(oid.in());
      desc.facet_ref = ref;
      // insere nos mapas do contexto
      std::string tempName(desc.name);
      std::pair<std::string, FacetDescription> pairFacetDesc(tempName, desc);
      context.getFacetDescs().insert(pairFacetDesc);
      std::pair<std::string, ExtendedFacetDescription> pairExtFacetDesc(tempName, extDesc);
      context.getExtendedFacetDescs().insert(pairExtFacetDesc);
      std::pair<std::string, void*> pairFacet(tempName, facet);
      context.getFacets().insert(pairFacet);
    #ifdef VERBOSE
      std::string ior(orb->object_to_string(ref.in()));
      std::cout << "\t[IOR:]" << ior << std::endl;
      std::cout << "\t[facet.name] = " << desc.name << std::endl;
      std::cout << "\t[facet.interface_name] = " << desc.interface_name << std::endl;
      std::cout << "[ComponentBuilder::addFacet() END]" << std::endl;
    #endif
    }

    ComponentContext* ComponentBuilder::newComponent(std::vector<ExtendedFacetDescription>& facetExtDescs,
        ComponentId& id) {
    #ifdef VERBOSE
      std::cout << "\n\n[ComponentBuilder::newComponent() BEGIN]" << std::endl;
    #endif
      ComponentContext* context = new ComponentContext(this, &id);
      // cria receptaculos (atualmente nao ha suporte a receptaculos)
      // cria facetas
      std::vector<ExtendedFacetDescription>::iterator it;
      for (it = facetExtDescs.begin(); it != facetExtDescs.end(); ++it) {
        addFacet(*context, *it);
      }
    #ifdef VERBOSE
      std::cout << "\n\n[ComponentBuilder::newComponent() END]" << std::endl;
    #endif
      return context;
    }

    ComponentContext* ComponentBuilder::newFullComponent(std::vector<ExtendedFacetDescription>& facetExtDescs, ComponentId& id) {
      bool foundIComponent = false, foundIReceptacles = false, foundIMetaInterface = false;
      for (unsigned int i = 0; i < facetExtDescs.size(); i++) {
          if (facetExtDescs[i].name.compare(ICOMPONENT_NAME) == 0)
            foundIComponent = true;
//          if (facetExtDescs[i].name.compare(IRECEPTACLES_NAME) == 0)
//            foundIReceptacles = true;
          if (facetExtDescs[i].name.compare(IMETAINTERFACE_NAME) == 0)
            foundIMetaInterface = true;
      }
      if (!foundIComponent) {
        scs::core::ExtendedFacetDescription iComponentDesc;
        iComponentDesc.name = "IComponent";
        iComponentDesc.interface_name = "IDL:scs/core/IComponent:1.0";
        iComponentDesc.instantiator = scs::core::IComponentImpl::instantiate;
        facetExtDescs.push_back(iComponentDesc);
      }
//      if (!foundIReceptacles) {
//        scs::core::ExtendedFacetDescription iReceptaclesDesc;
//        iReceptaclesDesc.name = "IReceptacles";
//        iReceptaclesDesc.interface_name = "IDL:scs/core/IReceptacles:1.0";
//        iReceptaclesDesc.instantiator = scs::core::IReceptaclesImpl::instantiate;
//        facetExtDescs.push_back(iReceptaclesDesc);
//      }
      if (!foundIMetaInterface) {
        scs::core::ExtendedFacetDescription iMetaDesc;
        iMetaDesc.name = "IMetaInterface";
        iMetaDesc.interface_name = "IDL:scs/core/IMetaInterface:1.0";
        iMetaDesc.instantiator = scs::core::IMetaInterfaceImpl::instantiate;
        facetExtDescs.push_back(iMetaDesc);
      }
      return newComponent(facetExtDescs, id);
    }
  }
}
