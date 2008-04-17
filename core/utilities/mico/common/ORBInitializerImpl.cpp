/*
** common/ORBInitializerImpl.cpp
*/

#include "ORBInitializerImpl.h"

#ifdef VERBOSE
  using namespace std ;
#endif

namespace openbus {
  namespace common {
    ORBInitializerImpl::ORBInitializerImpl( CredentialManager* pcredentialManager )
    {
      credentialManager = pcredentialManager ;
    }

    ORBInitializerImpl::~ORBInitializerImpl() {

    }

    void ORBInitializerImpl::pre_init( ORBInitInfo_ptr info )
    {
    #ifdef VERBOSE
      cout << "[ORBInitializerImpl::pre_init() BEGIN]" << endl ;
    #endif
      PortableInterceptor::ClientRequestInterceptor_var clientInterceptor = \
        new ClientInterceptor( credentialManager ) ;
      info->add_client_request_interceptor( clientInterceptor ) ;

      slotid = info->allocate_slot_id() ;
      CORBA::Object_var init_ref = info->resolve_initial_references( "PICurrent" ) ;
      Current_var pi_current = PortableInterceptor::Current::_narrow( init_ref ) ;
      serverInterceptor = new ServerInterceptor( pi_current, slotid ) ;

      PortableInterceptor::ServerRequestInterceptor_var serverRequestInterceptor = serverInterceptor ;
      info->add_server_request_interceptor( serverRequestInterceptor ) ;
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

    ServerInterceptor* ORBInitializerImpl::getServerInterceptor() {
      return serverInterceptor ;
    }
  }
}
