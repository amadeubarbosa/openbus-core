/*
** common/ORBInitializerImpl.cpp
*/

#include <omg/IOP.hh>

#include "ORBInitializerImpl.h"

#ifdef VERBOSE
  using namespace std;
#endif

IT_USING_NAMESPACE_STD

namespace openbus {
  namespace common {
    ORBInitializerImpl::ORBInitializerImpl()
    {
    #ifdef VERBOSE
      cout << "[ORBInitializerImpl::ORBInitializerImpl() BEGIN]" << endl;
    #endif
    #ifdef VERBOSE
      cout << "[ORBInitializerImpl::ORBInitializerImpl() END]" << endl;
    #endif
    }

    ORBInitializerImpl::~ORBInitializerImpl() {

    }

    void ORBInitializerImpl::pre_init(ORBInitInfo_ptr info)
    {
    #ifdef VERBOSE
      cout << "[ORBInitializerImpl::pre_init() BEGIN]" << endl;
    #endif
      IOP::CodecFactory_var codec_factory = info->codec_factory();
      IOP::Encoding cdr_encoding = {IOP::ENCODING_CDR_ENCAPS, 1, 2};
      PortableInterceptor::ClientRequestInterceptor_var clientInterceptor = \
          new ClientInterceptor(codec_factory->create_codec(cdr_encoding));
      info->add_client_request_interceptor(clientInterceptor);

      slotid = info->allocate_slot_id();
      CORBA::Object_var init_ref = info->resolve_initial_references("PICurrent");
      Current_var pi_current = PortableInterceptor::Current::_narrow(init_ref);

      codec_factory = info->codec_factory();
      serverInterceptor = new ServerInterceptor(pi_current, slotid, codec_factory->create_codec(cdr_encoding));

      PortableInterceptor::ServerRequestInterceptor_var serverRequestInterceptor = serverInterceptor ;
      info->add_server_request_interceptor(serverRequestInterceptor) ;
    #ifdef VERBOSE
      cout << "[ORBInitializerImpl::pre_init() END]" << endl;
    #endif
    }

    void ORBInitializerImpl::post_init(ORBInitInfo_ptr info)
    {
    #ifdef VERBOSE
      cout << "[ORBInitializerImpl::post_init() BEGIN]" << endl;
    #endif
    #ifdef VERBOSE
      cout << "[ORBInitializerImpl::post_init() END]" << endl;
    #endif
    }

    ServerInterceptor* ORBInitializerImpl::getServerInterceptor() {
      return serverInterceptor;
    }
  }
}

