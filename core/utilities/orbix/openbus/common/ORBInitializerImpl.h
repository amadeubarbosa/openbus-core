/*
** common/ORBInitializerImpl.h
*/

#ifndef ORBINITIALIZERIMPL_H_
#define ORBINITIALIZERIMPL_H_

#include <omg/PortableInterceptor.hh>

#include "ClientInterceptor.h"
#include "ServerInterceptor.h"

using namespace PortableInterceptor;

namespace openbus {
  namespace common {
    class ORBInitializerImpl : public ORBInitializer,
      public IT_CORBA::RefCountedLocalObject 
    {
        ServerInterceptor* serverInterceptor;
        SlotId slotid;
      public:
        ORBInitializerImpl();
        ~ORBInitializerImpl();

        void pre_init(ORBInitInfo_ptr info);
        void post_init(ORBInitInfo_ptr info);

        ServerInterceptor* getServerInterceptor();
    };
  }
}

#endif
