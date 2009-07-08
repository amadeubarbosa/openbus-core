/*
** common/ClientInterceptor.cpp
*/

#include "ClientInterceptor.h"

#ifdef VERBOSE
  #include <iostream>
#endif

#include "../../openbus.h"

using namespace openbusidl::acs;
#ifdef VERBOSE
  using namespace std;
#endif

namespace openbus {
  namespace common {

    std::map<CORBA::ORB*, openbusidl::acs::Credential**> 
      ClientInterceptor::credentials;
    openbusidl::acs::Credential** ClientInterceptor::credential = 0;

    ClientInterceptor::ClientInterceptor(IOP::Codec_ptr pcdr_codec) 
      IT_THROW_DECL(()) 
    {
    #ifdef VERBOSE
      Openbus::verbose->print("ClientInterceptor::ClientInterceptor() BEGIN");
      Openbus::verbose->indent();
    #endif
      cdr_codec = pcdr_codec;
    #ifdef VERBOSE
      Openbus::verbose->dedent();
      Openbus::verbose->print("ClientInterceptor::ClientInterceptor() END");
    #endif
    }

    ClientInterceptor::~ClientInterceptor() { }

    void ClientInterceptor::send_request(ClientRequestInfo_ptr ri) 
    IT_THROW_DECL((
      CORBA::SystemException,
      PortableInterceptor::ForwardRequest
    ))
    {
      CORBA::ORB_ptr orb;
      orb = ri->target()->_it_get_orb();
    #ifdef VERBOSE
      Openbus::verbose->print("ClientInterceptor::send_request() BEGIN");
      Openbus::verbose->indent();
      stringstream msg;
      msg << "Method: " << ri->operation();
      Openbus::verbose->print(msg.str());
    #endif
      credential = credentials[orb];
      if (credential != NULL) {
      #ifdef VERBOSE
        stringstream msg;
        msg << "Credential identifier: " << (*credential)->identifier;
        Openbus::verbose->print(msg.str());
      #endif
        IOP::ServiceContext sc;
        sc.context_id = 1234;

        CORBA::Any_var any;
        any <<= **credential;
        CORBA::OctetSeq_var octets;
        octets = cdr_codec->encode_value(any);
        IOP::ServiceContext::_context_data_seq seq(
          octets->length(),
          octets->length(),
          octets->get_buffer(),
          IT_FALSE);
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
      Openbus::verbose->dedent();
      Openbus::verbose->print("ClientInterceptor::send_request() END");
    #endif
    }

    char* ClientInterceptor::name() IT_THROW_DECL((CORBA::SystemException)) {
      return CORBA::it_string_dup_eh("AccessControl");
    }
    void ClientInterceptor::send_poll( ClientRequestInfo_ptr ri ) 
      IT_THROW_DECL((CORBA::SystemException)) {}
    void ClientInterceptor::receive_reply( ClientRequestInfo_ptr ri ) 
      IT_THROW_DECL((CORBA::SystemException)) {}
    void ClientInterceptor::receive_exception( ClientRequestInfo_ptr ri ) 
      IT_THROW_DECL((
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest
    )){}
    void ClientInterceptor::receive_other( ClientRequestInfo_ptr ri ) 
      IT_THROW_DECL((
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest
    )){}
  }
}

