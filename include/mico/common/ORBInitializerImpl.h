/*
** mico/common/ORBInitializerImpl.h
*/

#ifndef ORBINITIALIZERIMPL_H_
#define ORBINITIALIZERIMPL_H_

#include <CORBA.h>
#include <mico/pi.h>
#include <mico/pi_impl.h>

#include "ClientInterceptor.h"

using namespace PortableInterceptor ;
using namespace clientinterceptor ;

namespace orbinitializerimpl {

  class ORBInitializerImpl : public ORBInitializer {
      CredentialHolder* credentialHolder ;
    public:
      ORBInitializerImpl( CredentialHolder* pcredentialHolder ) ;
      ~ORBInitializerImpl() ;

      void pre_init( ORBInitInfo_ptr info ) ;
      void post_init( ORBInitInfo_ptr info ) ;
  } ;
}

#endif
