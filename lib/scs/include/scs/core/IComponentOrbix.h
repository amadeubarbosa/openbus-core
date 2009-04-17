/*
** scs/core/IComponentOrbix.h
*/

#ifndef ICOMPONENTIMPL_H_
#define ICOMPONENTIMPL_H_

#include <map>
#include <scs/core/ComponentContextOrbix.h>

#include <stubs/scsS.hh>

namespace scs {
  namespace core {
    class ComponentContext;

    class IComponentImpl : virtual public POA_scs::core::IComponent {
      private:
        PortableServer::POA_ptr _poa;
        CORBA::ORB_ptr _orb;
        ComponentId componentId;
        std::map<std::string, FacetDescription>* facets;

        ComponentContext* context;
        IComponentImpl(ComponentContext* context);

      public:
        static void* instantiate(ComponentContext* context);
        static void destruct(void* obj);
        ~IComponentImpl();

        void startup() IT_THROW_DECL((CORBA::SystemException, scs::core::StartupFailed));
        void shutdown() IT_THROW_DECL((CORBA::SystemException, scs::core::ShutdownFailed));
        CORBA::Object_ptr getFacet(const char* facet_interface) IT_THROW_DECL((CORBA::SystemException));
        CORBA::Object_ptr getFacetByName(const char* facet) IT_THROW_DECL((CORBA::SystemException));
        ComponentId* getComponentId() IT_THROW_DECL((CORBA::SystemException));
      };
  }
}

#endif
