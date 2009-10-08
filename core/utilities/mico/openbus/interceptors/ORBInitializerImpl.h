/*
** interceptors/ORBInitializerImpl.h
*/

#ifndef ORBINITIALIZERIMPL_H_
#define ORBINITIALIZERIMPL_H_

#include <CORBA.h>

#include "ClientInterceptor.h"
#include "ServerInterceptor.h"

using namespace PortableInterceptor;

namespace openbus {
  namespace interceptors {
    class ORBInitializerImpl : public ORBInitializer {
      private:
        IOP::Codec_var codec;
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