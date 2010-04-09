/*
** interceptors/ORBInitializerImpl.h
*/

#ifndef ORBINITIALIZERIMPL_H_
#define ORBINITIALIZERIMPL_H_

#ifndef OPENBUS_MICO
  #include <omg/PortableInterceptor.hh>
#endif

#include "ClientInterceptor.h"
#include "ServerInterceptor.h"

using namespace PortableInterceptor;

namespace openbus {
  namespace interceptors {

  /**
  * Define as políticas para a validação de credenciais interceptadas.
  */ 
    enum CredentialValidationPolicy {

     /**
     * Indica que as credenciais interceptadas serão sempre validadas.
     */
      ALWAYS,

     /**
     * Indica que as credenciais interceptadas serão validadas e 
     * armazenadas em um cache.
     */
      CACHED,

     /**
     * Indica que as credenciais interceptadas não serão validadas.
     */
      NONE
    };

        
    class ORBInitializerImpl : public ORBInitializer
    #ifndef OPENBUS_MICO
                              ,public IT_CORBA::RefCountedLocalObject 
    #endif
    {
        static bool singleInstance;
        IOP::Codec_var codec;
        ServerInterceptor* serverInterceptor;
        ClientInterceptor* clientInterceptor;
        SlotId slotid;
      public:
        ORBInitInfo* _info;
        ORBInitializerImpl();
        ~ORBInitializerImpl();

        void pre_init(ORBInitInfo_ptr info);
        void post_init(ORBInitInfo_ptr info);

        ServerInterceptor* getServerInterceptor();
    };
  }
}

#endif
