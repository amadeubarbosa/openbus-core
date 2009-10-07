/*
** interceptors/ServerInterceptor.h
*/

#ifndef SERVERINTERCEPTOR_H_
#define SERVERINTERCEPTOR_H_

#include <CORBA.h>

#include "../../stubs/access_control_service.h"

using namespace PortableInterceptor;

namespace openbus {
  namespace interceptors {

    class ServerInterceptor : public ServerRequestInterceptor
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
