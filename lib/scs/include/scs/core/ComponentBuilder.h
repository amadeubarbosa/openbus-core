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
        IComponentImpl* createComponent(const char* name, unsigned long version, const char* facet_name, \
          const char* interface_name, PortableServer::ServantBase* obj);
    };
  }
}

#endif
