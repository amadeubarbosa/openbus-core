/*
** ComponentBuilder.h
*/

#ifndef COMPONENTBUILDER_H_
#define COMPONENTBUILDER_H_

#include "IComponentOrbix.h"

namespace scs {
  namespace core {
    class ComponentBuilder {
      private:
        CORBA::ORB* orb;
        PortableServer::POA* poa;
      public:
        ComponentBuilder(CORBA::ORB* _orb, PortableServer::POA* _poa);
        ~ComponentBuilder();
        IComponentImpl* createComponent(const char* name, CORBA::Octet major_version, \
            CORBA::Octet minor_version, CORBA::Octet patch_version, const char* platform_spec, \
            const char* facet_name, const char* interface_name, PortableServer::ServantBase* obj);
    };
  }
}

#endif
