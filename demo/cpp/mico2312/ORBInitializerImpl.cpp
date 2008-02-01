/*
** ORBInitializerImpl.cpp
*/

#include "mico/common/ORBInitializerImpl.h"

using namespace clientinterceptor ;
#ifdef VERBOSE
using namespace std ;
#endif

namespace orbinitializerimpl {

  ORBInitializerImpl::ORBInitializerImpl( CredentialHolder* pcredentialHolder )
  {
    credentialHolder = pcredentialHolder ;
    credentialHolder->identifier = "" ;
    credentialHolder->entityName = "" ;
  }

  ORBInitializerImpl::~ORBInitializerImpl() {

  }

  void ORBInitializerImpl::pre_init( ORBInitInfo_ptr info )
  {
  #ifdef VERBOSE
    cout << "[ORBInitializerImpl::pre_init() BEGIN]" << endl ;
  #endif
    PortableInterceptor::ClientRequestInterceptor_var clientInterceptor = \
      new ClientInterceptor( *credentialHolder ) ;
    info->add_client_request_interceptor( clientInterceptor ) ;
  #ifdef VERBOSE
    cout << "[ORBInitializerImpl::pre_init() END]" << endl ;
  #endif
  }

  void ORBInitializerImpl::post_init( ORBInitInfo_ptr info )
  {
  #ifdef VERBOSE
    cout << "[ORBInitializerImpl::post_init() BEGIN]" << endl ;
  #endif
  #ifdef VERBOSE
    cout << "[ORBInitializerImpl::post_init() END]" << endl ;
  #endif
  }

}
