/*
** common/ClientInterceptor.h
*/

#ifndef CLIENTINTERCEPTOR_H_
#define CLIENTINTERCEPTOR_H_

#include <map>
#include <string.h>
#include <orbix/corba.hh>
#include <omg/PortableInterceptor.hh>

#include "../../stubs/access_control_service.hh"

using namespace PortableInterceptor;

namespace openbus {
  namespace common {
    class ClientInterceptor : public ClientRequestInterceptor, 
      public IT_CORBA::RefCountedLocalObject 
    {
      private:
        IOP::Codec_ptr cdr_codec;
      public:
        static openbusidl::acs::Credential_var credential;

        ClientInterceptor(IOP::Codec_ptr pcdr_codec) IT_THROW_DECL(());
        ~ClientInterceptor();
        void send_request(ClientRequestInfo_ptr ri) IT_THROW_DECL((
          CORBA::SystemException,
          PortableInterceptor::ForwardRequest
        ));
        void send_poll(ClientRequestInfo_ptr ri) 
          IT_THROW_DECL((CORBA::SystemException));
        void receive_reply(ClientRequestInfo_ptr ri) 
          IT_THROW_DECL((CORBA::SystemException));
        void receive_exception(ClientRequestInfo_ptr ri) IT_THROW_DECL((
          CORBA::SystemException,
          PortableInterceptor::ForwardRequest
        ));
        void receive_other(ClientRequestInfo_ptr ri) IT_THROW_DECL((
          CORBA::SystemException,
          PortableInterceptor::ForwardRequest
        ));
        char* name() IT_THROW_DECL((CORBA::SystemException));
    };
  }
}

#endif
