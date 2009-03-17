/*
** IMetaInterfaceImpl.h
*/

#ifndef IMETAINTERFACEIMPL_H_
#define IMETAINTERFACEIMPL_H_

#include <map>
#include <scs/core/ComponentContextOrbix.h>

#include <stubs/scsS.hh>

namespace scs {
  namespace core {
    class IMetaInterfaceImpl : virtual public POA_scs::core::IMetaInterface {
    private:
      ComponentContext* context;
      std::map<std::string, FacetDescription>* facets;
      IMetaInterfaceImpl(ComponentContext* context);
    public:
      static void* instantiate(ComponentContext* context);
      ~IMetaInterfaceImpl();

      FacetDescriptions* getFacets() IT_THROW_DECL((CORBA::SystemException));
      FacetDescriptions* getFacetsByName(const NameList&  names)
        IT_THROW_DECL((CORBA::SystemException, InvalidName));
      ReceptacleDescriptions* getReceptacles()
        IT_THROW_DECL((CORBA::SystemException));
      ReceptacleDescriptions* getReceptaclesByName(const NameList &  names)
        IT_THROW_DECL((CORBA::SystemException, InvalidName));
    };
  }
}


#endif /* IMETAINTERFACEIMPL_H_ */
