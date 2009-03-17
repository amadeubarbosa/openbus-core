/*
** IMetaInterfaceOrbix.cpp
*/

#include <scs/core/IMetaInterfaceOrbix.h>

#ifdef VERBOSE
using namespace std;
#endif

namespace scs {
  namespace core {
    IMetaInterfaceImpl::IMetaInterfaceImpl(ComponentContext* context)
    {
    #ifdef VERBOSE
      cout << "[IMetaInterfaceImpl::IMetaInterfaceImpl() BEGIN]" << endl;
    #endif
      this->context = context;
      this->facets = &(context->getFacetDescs());
    #ifdef VERBOSE
      cout << "[IMetaInterfaceImpl::IMetaInterfaceImpl() END]" << endl;
    #endif
    }

    IMetaInterfaceImpl::~IMetaInterfaceImpl() {
    #ifdef VERBOSE
      cout << "\n\n[IMetaInterfaceImpl::~IMetaInterfaceImpl() BEGIN]" << endl;
    #endif
    #ifdef VERBOSE
      cout << "[IMetaInterfaceImpl::~IMetaInterfaceImpl() END]" << endl;
    #endif
    }

    void* IMetaInterfaceImpl::instantiate(ComponentContext* context) {
      return (void*) new IMetaInterfaceImpl(context);
    }

    FacetDescriptions* IMetaInterfaceImpl::getFacets() IT_THROW_DECL((CORBA::SystemException)) {
    #ifdef VERBOSE
      cout << "\n\n[IMetaInterfaceImpl::getFacets() BEGIN]" << endl;
    #endif
      int size = facets->size();
    #ifdef VERBOSE
      cout << "\t[Número de facetas disponibilizadas: " << size << "]" << endl;
    #endif
      // constroi array com controle de memoria pelo ORB
      FacetDescriptions_var descs = new FacetDescriptions;
      descs->length(size);
      // copia conteudo
      int i = 0;
      std::map<std::string, FacetDescription>::iterator it;
      for(it = facets->begin(); it != facets->end(); ++it)
      {
        FacetDescription_var f = new FacetDescription(it->second);
        descs[i++] = f;
      }
    #ifdef VERBOSE
      cout << "[IMetaInterfaceImpl::getFacets() END]" << endl;
    #endif
      return descs._retn();
    }

    FacetDescriptions* IMetaInterfaceImpl::getFacetsByName(const NameList&  names) IT_THROW_DECL((CORBA::SystemException, InvalidName)) {
    #ifdef VERBOSE
      cout << "\n\n[IMetaInterfaceImpl::getFacetsByName() BEGIN]" << endl;
    #endif
      int size = names.length();
    #ifdef VERBOSE
      cout << "\t[Número de facetas procuradas: " << size << "]" << endl;
    #endif
      // constroi array com controle de memoria pelo ORB
      FacetDescriptions_var descs = new FacetDescriptions;
      descs->length(size);
      int i;
      // copia conteudo
      for(i = 0; i < size; i++)
      {
    #ifdef VERBOSE
      cout << "\t[Faceta: " << names[i] << "]" << endl;
    #endif
        std::map<std::string, FacetDescription>::const_iterator it = facets->find(std::string(names[i]));
        if (it != facets->end()) {
          FacetDescription_var f = new FacetDescription((FacetDescription)it->second);
          descs[i] = f;
        }
        else
          throw new InvalidName(names[i]);
      }
    #ifdef VERBOSE
      cout << "\t[Número de facetas encontradas: " << descs->length() << "]" << endl;
      cout << "[IMetaInterfaceImpl::getFacetsByName() END]" << endl;
    #endif
      return descs._retn();
    }

    ReceptacleDescriptions* IMetaInterfaceImpl::getReceptacles() IT_THROW_DECL((CORBA::SystemException)) {
      // metodo nao faz nada enquanto nao houver suporte a receptaculos.
      return NULL;
    }

    ReceptacleDescriptions* IMetaInterfaceImpl::getReceptaclesByName(const NameList &  names) IT_THROW_DECL((CORBA::SystemException, InvalidName)) {
      //lanca invalidname
      // metodo nao faz nada enquanto nao houver suporte a receptaculos.
      return NULL;
    }
  }
}
