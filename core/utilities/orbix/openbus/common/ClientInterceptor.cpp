/*
** common/ClientInterceptor.cpp
*/

#include "ClientInterceptor.h"

#ifdef VERBOSE
  #include <iostream>
#endif

#include "../../stubs/access_control_service.hh"

using namespace openbusidl::acs;
#ifdef VERBOSE
  using namespace std;
#endif

namespace openbus {
  namespace common {
    ClientInterceptor::ClientInterceptor(openbusidl::acs::Credential** pcredential, IOP::Codec_ptr pcdr_codec) IT_THROW_DECL(()) {
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::ClientInterceptor() BEGIN]" << endl;
    #endif
      credential = pcredential;
      cdr_codec = pcdr_codec;
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::ClientInterceptor() END]" << endl;
    #endif
    }

    ClientInterceptor::~ClientInterceptor() {
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::~ClientInterceptor() BEGIN]" << endl;
    #endif
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::~ClientInterceptor() END]" << endl;
    #endif
    }

    void ClientInterceptor::send_request(ClientRequestInfo_ptr ri) IT_THROW_DECL((
      CORBA::SystemException,
      PortableInterceptor::ForwardRequest
    ))
    {
    #ifdef VERBOSE
      cout << "\n\n[ClientInterceptor::send_request() BEGIN]" << endl;
      cout << "Method: " << ri->operation() << endl;
    #endif
      if (*credential != NULL) {
        IOP::ServiceContext sc;
        sc.context_id = 1234;

        CORBA::Any_var any;
        any <<= **credential;
        CORBA::OctetSeq_var octets;
//        PICodec::Codec_impl* codec = new PICodec::Codec_impl;
//        en = codec->encode_value(any);
        octets = cdr_codec->encode_value(any);
IOP::ServiceContext::_context_data_seq seq(
                           octets->length(),
                           octets->length(),
                           octets->get_buffer(),
                           IT_FALSE);

        sc.context_data = seq;

      #ifdef VERBOSE
        CORBA::ULong z;
        cout << "[Context Data:]";
        for ( z = 0; z < sc.context_data.length(); z++ ) {
          printf( "%u ", sc.context_data[ z ] );
        }
      #endif

        ri->add_request_service_context(sc, true);
      }
    #ifdef VERBOSE
      cout << "\n[ClientInterceptor::send_request() END]" << endl;
    #endif
    }

    char* ClientInterceptor::name() IT_THROW_DECL((CORBA::SystemException)) {
      return CORBA::it_string_dup_eh("AccessControl");
    }
    void ClientInterceptor::send_poll( ClientRequestInfo_ptr ri ) IT_THROW_DECL((CORBA::SystemException)) {}
    void ClientInterceptor::receive_reply( ClientRequestInfo_ptr ri ) IT_THROW_DECL((CORBA::SystemException)) {}
    void ClientInterceptor::receive_exception( ClientRequestInfo_ptr ri ) IT_THROW_DECL((
      CORBA::SystemException,
      PortableInterceptor::ForwardRequest
    )){}
    void ClientInterceptor::receive_other( ClientRequestInfo_ptr ri ) IT_THROW_DECL((
      CORBA::SystemException,
      PortableInterceptor::ForwardRequest
    )){}
  }
}
