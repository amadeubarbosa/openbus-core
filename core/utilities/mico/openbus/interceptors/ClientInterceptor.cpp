/*
** interceptors/ClientInterceptor.cpp
*/

#include "ClientInterceptor.h"

#ifdef VERBOSE
  #include <iostream>
#endif

#include "../../openbus.h"
#include <mico/pi_impl.h>

using namespace openbusidl::acs;

namespace openbus {
  namespace interceptors {
    openbusidl::acs::Credential* ClientInterceptor::credential = 0;

    ClientInterceptor::ClientInterceptor(IOP::Codec_ptr pcdr_codec) 
      throw() 
    {
    #ifdef VERBOSE
      Openbus::verbose->print("ClientInterceptor::ClientInterceptor() BEGIN");
      Openbus::verbose->indent();
    #endif
      cdr_codec = pcdr_codec;
    #ifdef VERBOSE
      Openbus::verbose->dedent("ClientInterceptor::ClientInterceptor() END");
    #endif
    }

    ClientInterceptor::~ClientInterceptor() { }

    void ClientInterceptor::send_request(ClientRequestInfo_ptr ri) 
      throw(
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest)
    {
    #ifdef VERBOSE
      Openbus::verbose->print("ClientInterceptor::send_request() BEGIN");
      Openbus::verbose->indent();
      stringstream msg;
      char * operation = ri->operation();
      msg << "Method: " << operation;
      Openbus::verbose->print(msg.str());
      delete operation;
    #endif
      if (credential) {
      #ifdef VERBOSE
        stringstream msg;
        msg << "Credential identifier: " << credential->identifier;
        Openbus::verbose->print(msg.str());
      #endif
        IOP::ServiceContext sc;
        sc.context_id = 1234;

        CORBA::Any any;
        any <<= *credential;
        CORBA::OctetSeq_var octets;
        PICodec::Codec_impl* codec = new PICodec::Codec_impl;
        octets = codec->encode_value(any);
        delete codec;
//        octets = cdr_codec->encode_value(any.in());
        IOP::ServiceContext::_context_data_seq seq(
          octets->length(),
          octets->length(),
          octets->get_buffer(),
          0);
        sc.context_data = seq;

      #ifdef VERBOSE
        CORBA::ULong z;
        stringstream contextData;
        contextData << "Context data: ";
        for ( z = 0; z < sc.context_data.length(); z++ ) {
          contextData <<  (unsigned) sc.context_data[ z ] << " ";
        }
        Openbus::verbose->print(contextData.str());
      #endif

        ri->add_request_service_context(sc, true);
      }
    #ifdef VERBOSE
      Openbus::verbose->dedent("ClientInterceptor::send_request() END");
    #endif
    }

    char* ClientInterceptor::name() 
      throw(CORBA::SystemException) 
    {
    /* O Mico 2.3.11 e 2.3.13 nao adquirem propriedade desta string,
    ** portanto nao se deve usar o string_dup().
    */ 
      return "AccessControl"; 
    }
    void ClientInterceptor::send_poll(ClientRequestInfo_ptr ri)
      throw(CORBA::SystemException) {}
    void ClientInterceptor::receive_reply(ClientRequestInfo_ptr ri)
      throw(CORBA::SystemException) {}
    void ClientInterceptor::receive_exception( ClientRequestInfo_ptr ri ) 
      throw(
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest) {}
    void ClientInterceptor::receive_other( ClientRequestInfo_ptr ri ) 
      throw(
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest) {}
    void ClientInterceptor::destroy() {}
  }
}

