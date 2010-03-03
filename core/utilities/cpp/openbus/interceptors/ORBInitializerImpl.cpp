/*
** interceptors/ORBInitializerImpl.cpp
*/

#ifndef OPENBUS_MICO
  #include <omg/IOP.hh>
#endif

#include "ORBInitializerImpl.h"
#include "../../openbus.h"

using namespace std;

namespace openbus {
  namespace interceptors {
    bool ORBInitializerImpl::singleInstance = false;
    ORBInitializerImpl::ORBInitializerImpl()
    {
/*    clientInterceptor = 0;
      serverInterceptor = 0;
      */
      _info = 0;
    }

    ORBInitializerImpl::~ORBInitializerImpl() {
      Openbus::logger->log(INFO, "ORBInitializerImpl::~ORBInitializerImpl() BEGIN");
      Openbus::logger->indent();
    #ifdef OPENBUS_MICO
/*
      if (clientInterceptor) {
        delete clientInterceptor;
      }
      if (serverInterceptor) {
        delete serverInterceptor;
      }
      if (_info) {
        delete _info->orb_id();
        delete _info;
      }
      */
    #endif
      Openbus::logger->dedent(INFO, "ORBInitializerImpl::~ORBInitializerImpl() END");
    }

    void ORBInitializerImpl::pre_init(ORBInitInfo_ptr info)
    {
      Openbus::logger->log(INFO, "ORBInitializerImpl::pre_init() BEGIN");
      Openbus::logger->indent();
      _info = info;
    #ifdef OPENBUS_MICO
/*      if (clientInterceptor) {
        delete clientInterceptor;
      }
      if (serverInterceptor) {
        delete serverInterceptor;
      }
      if (_info) {
        delete _info;
      }
      */
      if (!singleInstance) {
        singleInstance = true;
    #endif
      IOP::CodecFactory_var codec_factory = _info->codec_factory();
      IOP::Encoding cdr_encoding = {IOP::ENCODING_CDR_ENCAPS, 1, 2};
      codec = codec_factory->create_codec(cdr_encoding);

    #ifdef OPENBUS_MICO
      clientInterceptor = \
          new ClientInterceptor(codec);
    #else
      PortableInterceptor::ClientRequestInterceptor_var clientInterceptor = \
          new ClientInterceptor(codec);
    #endif
      _info->add_client_request_interceptor(clientInterceptor);

      slotid = _info->allocate_slot_id();

      CORBA::Object_var init_ref = 
        _info->resolve_initial_references("PICurrent");
      Current_var pi_current = PortableInterceptor::Current::_narrow(init_ref);

      serverInterceptor = new ServerInterceptor(
        pi_current, 
        slotid, 
        codec);

      PortableInterceptor::ServerRequestInterceptor_var 
        serverRequestInterceptor = serverInterceptor ;
      _info->add_server_request_interceptor(serverRequestInterceptor) ;
    #ifdef OPENBUS_MICO
      }
    #endif
      Openbus::logger->dedent(INFO, "ORBInitializerImpl::pre_init() END");
    }

    void ORBInitializerImpl::post_init(ORBInitInfo_ptr info) { }

    ServerInterceptor* ORBInitializerImpl::getServerInterceptor() {
      return serverInterceptor;
    }
  }
}

