/*
** interceptors/ClientInterceptor.h
*/

#ifndef CLIENTINTERCEPTOR_H_
#define CLIENTINTERCEPTOR_H_

#include <map>
#include <string.h>
#include <CORBA.h>

#include "../../stubs/access_control_service.h"

using namespace PortableInterceptor;

namespace openbus {
  namespace interceptors {
    class ClientInterceptor : public ClientRequestInterceptor
    {
      private:
        IOP::Codec_ptr cdr_codec;
      public:
        static openbusidl::acs::Credential_var credential;

        ClientInterceptor(IOP::Codec_ptr pcdr_codec) 
          throw();
        ~ClientInterceptor();
        void send_request(ClientRequestInfo_ptr ri) 
          throw (
            CORBA::SystemException,
            PortableInterceptor::ForwardRequest);
        void send_poll(ClientRequestInfo_ptr ri) 
          throw(CORBA::SystemException);
        void receive_reply(ClientRequestInfo_ptr ri) 
          throw(CORBA::SystemException);
        void receive_exception(ClientRequestInfo_ptr ri) 
          throw(
            CORBA::SystemException,
            PortableInterceptor::ForwardRequest);
        void receive_other(ClientRequestInfo_ptr ri) 
          throw(
            CORBA::SystemException,
            PortableInterceptor::ForwardRequest);
        char* name() 
          throw(CORBA::SystemException);
        void destroy();
    };
  }
}

#endif
