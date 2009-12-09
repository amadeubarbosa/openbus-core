/*
** interceptors/ServerInterceptor.h
*/

#ifndef SERVERINTERCEPTOR_H_
#define SERVERINTERCEPTOR_H_

#ifdef OPENBUS_MICO
  #include <CORBA.h>
  #include "../../stubs/mico/access_control_service.h"
#else
  #include <orbix/corba.hh>
  #include <omg/PortableInterceptor.hh>
  #include "../../stubs/orbix/access_control_service.hh"
#endif

using namespace PortableInterceptor;

namespace openbus {
  namespace interceptors {

    class ServerInterceptor : public ServerRequestInterceptor
    #ifndef OPENBUS_MICO
                              ,public IT_CORBA::RefCountedLocalObject 
    #endif
    {
      private:
        Current* picurrent;
        SlotId slotid;
        IOP::Codec_ptr cdr_codec;
      public:
        ServerInterceptor(Current* ppicurrent, 
          SlotId pslotid, 
          IOP::Codec_ptr pcdr_codec);
        ~ServerInterceptor();
        void receive_request_service_contexts(ServerRequestInfo*);
        void receive_request(ServerRequestInfo_ptr ri);
        void send_reply(ServerRequestInfo*);
        void send_exception(ServerRequestInfo*);
        void send_other(ServerRequestInfo*);
        char* name();
        void destroy();
        openbusidl::acs::Credential_var getCredential();
    };
  }
}

#endif
