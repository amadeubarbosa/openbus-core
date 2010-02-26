/*
** interceptors/ClientInterceptor.cpp
*/

#include "ClientInterceptor.h"

#ifdef VERBOSE
  #include <iostream>
#endif

#include "../../openbus.h"

using namespace tecgraf::openbus::core::v1_05;

namespace openbus {
  namespace interceptors {
    access_control_service::Credential* ClientInterceptor::credential = 0;

    ClientInterceptor::ClientInterceptor(IOP::Codec_ptr pcdr_codec)  
    {
    #ifdef VERBOSE
      Openbus::logger->log(INFO, "ClientInterceptor::ClientInterceptor() BEGIN");
      Openbus::logger->indent();
    #endif
      cdr_codec = pcdr_codec;
    #ifdef VERBOSE
      Openbus::logger->dedent(INFO, "ClientInterceptor::ClientInterceptor() END");
    #endif
    }

    ClientInterceptor::~ClientInterceptor() { }

    void ClientInterceptor::send_request(ClientRequestInfo_ptr ri) 
      throw(
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest)
    {
    #ifdef VERBOSE
      Openbus::logger->log(INFO, "ClientInterceptor::send_request() BEGIN");
      Openbus::logger->indent();
      stringstream msg;
      char * operation = ri->operation();
      msg << "Method: " << operation;
      Openbus::logger->log(INFO, msg.str());
      free(operation);
    #endif
      if (credential) {
      #ifdef VERBOSE
        stringstream msg;
        msg << "Credential identifier: " << credential->identifier;
        Openbus::logger->log(INFO, msg.str());
      #endif
        IOP::ServiceContext sc;
        sc.context_id = 1234;

        CORBA::Any any;
        any <<= *credential;
        CORBA::OctetSeq_var octets;
        octets = cdr_codec->encode_value(any);
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
        Openbus::logger->log(INFO, contextData.str());
      #endif

        ri->add_request_service_context(sc, true);
      }
    #ifdef VERBOSE
      Openbus::logger->dedent(INFO, "ClientInterceptor::send_request() END");
    #endif
    }

    char* ClientInterceptor::name() 
      throw(CORBA::SystemException)
    {
    #ifdef OPENBUS_MICO
      return "AccessControl";
    #else
      return CORBA::string_dup("AccessControl");
    #endif
    }
    void ClientInterceptor::send_poll( ClientRequestInfo_ptr ri ) 
      throw(CORBA::SystemException) 
    {}
    void ClientInterceptor::receive_reply( ClientRequestInfo_ptr ri ) 
      throw(CORBA::SystemException) 
    {}
    void ClientInterceptor::receive_exception( ClientRequestInfo_ptr ri ) 
      throw(
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest)
    {}
    void ClientInterceptor::receive_other( ClientRequestInfo_ptr ri ) 
      throw(
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest)
    {}
    void ClientInterceptor::destroy() {}
  }
}

