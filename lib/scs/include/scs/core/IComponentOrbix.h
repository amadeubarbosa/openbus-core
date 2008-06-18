/*
** scs/core/IComponentOrbix.h
*/

#ifndef ICOMPONENTIMPL_H_
#define ICOMPONENTIMPL_H_

#include <map>

#include <stubs/scsS.hh>

namespace scs {
  namespace core {
    class IComponentImpl : virtual public POA_scs::core::IComponent {
        PortableServer::POA_ptr _poa;
        CORBA::ORB_ptr _orb;
        ComponentId_var componentId;
        std::map<const char*, FacetDescription> facets;
        std::map<const char*, FacetDescription>::iterator it;
      public:
        IComponentImpl(const char* name, unsigned long version, \
                        CORBA::ORB_ptr orb, PortableServer::POA_ptr poa);
        ~IComponentImpl();

        void addFacet(const char* name, const char* interface_name, \
            PortableServer::ServantBase* obj );
        void startup() IT_THROW_DECL((CORBA::SystemException, scs::core::StartupFailed));
        void shutdown() IT_THROW_DECL((CORBA::SystemException, scs::core::ShutdownFailed));
        CORBA::Object_ptr getFacet(const char* facet_interface) IT_THROW_DECL((CORBA::SystemException));
        CORBA::Object_ptr getFacetByName(const char* facet) IT_THROW_DECL((CORBA::SystemException));
        ComponentId* getComponentId() IT_THROW_DECL((CORBA::SystemException));
    };
  }
}

#endif
