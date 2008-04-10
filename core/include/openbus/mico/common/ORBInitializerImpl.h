/*
** mico/common/ORBInitializerImpl.h
*/

#ifndef ORBINITIALIZERIMPL_H_
#define ORBINITIALIZERIMPL_H_

#include <CORBA.h>
#include <mico/pi.h>
#include <mico/pi_impl.h>

#include "ClientInterceptor.h"
#include "ServerInterceptor.h"

using namespace PortableInterceptor ;

namespace openbus {
  namespace common {
    class ORBInitializerImpl : public ORBInitializer {
        ServerInterceptor* serverInterceptor ;
        CredentialManager* credentialManager ;
        SlotId slotid ;
     public:
        ORBInitializerImpl( CredentialManager* pcredentialManager ) ;
        ~ORBInitializerImpl() ;

        void pre_init( ORBInitInfo_ptr info ) ;
        void post_init( ORBInitInfo_ptr info ) ;

        ServerInterceptor* getServerInterceptor() ;
    } ;
  }
}

#endif
