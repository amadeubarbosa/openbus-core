/*
** interceptors/ORBInitializerImpl.cpp
*/

#include <omg/IOP.hh>

#include "ORBInitializerImpl.h"
#include "../../openbus.h"

using namespace std;

namespace openbus {
  namespace interceptors {
    ORBInitializerImpl::ORBInitializerImpl()
    {
    #ifdef VERBOSE
      Openbus::verbose->print("ORBInitializerImpl::ORBInitializerImpl() BEGIN");
      Openbus::verbose->indent();
    #endif
    #ifdef VERBOSE
      Openbus::verbose->dedent("ORBInitializerImpl::ORBInitializerImpl() END");
    #endif
    }

    ORBInitializerImpl::~ORBInitializerImpl() {
    }

    void ORBInitializerImpl::pre_init(ORBInitInfo_ptr info)
    {
    #ifdef VERBOSE
      Openbus::verbose->print("ORBInitializerImpl::pre_init() BEGIN");
      Openbus::verbose->indent();
    #endif
      IOP::CodecFactory_var codec_factory = info->codec_factory();
      IOP::Encoding cdr_encoding = {IOP::ENCODING_CDR_ENCAPS, 1, 2};
      IOP::Codec_var codec = codec_factory->create_codec(cdr_encoding);

      PortableInterceptor::ClientRequestInterceptor_var clientInterceptor = \
          new ClientInterceptor(codec);
      info->add_client_request_interceptor(clientInterceptor);

      slotid = info->allocate_slot_id();

      CORBA::Object_var init_ref = 
        info->resolve_initial_references("PICurrent");
      Current_var pi_current = PortableInterceptor::Current::_narrow(init_ref);

      serverInterceptor = new ServerInterceptor(
        pi_current, 
        slotid, 
        codec);

      PortableInterceptor::ServerRequestInterceptor_var 
        serverRequestInterceptor = serverInterceptor ;
      info->add_server_request_interceptor(serverRequestInterceptor) ;

    #ifdef VERBOSE
      Openbus::verbose->dedent("ORBInitializerImpl::pre_init() END");
    #endif
    }

    void ORBInitializerImpl::post_init(ORBInitInfo_ptr info) { }

    ServerInterceptor* ORBInitializerImpl::getServerInterceptor() {
      return serverInterceptor;
    }
  }
}

