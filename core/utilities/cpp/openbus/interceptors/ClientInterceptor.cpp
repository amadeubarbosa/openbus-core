/*
** interceptors/ClientInterceptor.cpp
*/

#include "ClientInterceptor.h"

#include "../../openbus.h"

#ifndef OPENBUS_MICO
  #include <it_ts/thread.h>
#endif

using namespace tecgraf::openbus::core::v1_05;

namespace openbus {
  namespace interceptors {
    access_control_service::Credential* ClientInterceptor::credential = 0;

    void ClientInterceptor::loadOperationObjectKey() {
      operationObjectKey["renewLease"] = "LP_v1_05";
      operationObjectKey["loginByPassword"] = "ACS_v1_05";
      operationObjectKey["loginByCertificate"] = "ACS_v1_05";
      operationObjectKey["getChallenge"] = "ACS_v1_05";
      operationObjectKey["logout"] = "ACS_v1_05";
      operationObjectKey["isValid"] = "ACS_v1_05";
      operationObjectKey["areValid"] = "ACS_v1_05";
      operationObjectKey["getEntryCredential"] = "ACS_v1_05";
      operationObjectKey["getAllEntryCredential"] = "ACS_v1_05";
      operationObjectKey["addObserver"] = "ACS_v1_05";
      operationObjectKey["removerObserver"] = "ACS_v1_05";
      operationObjectKey["addCredentialToObserver"] = "ACS_v1_05";
      operationObjectKey["removeCredentialFromObserver"] = "ACS_v1_05";
      operationObjectKey["register"] = "RS_v1_05";
      operationObjectKey["unregister"] = "RS_v1_05";
      operationObjectKey["update"] = "RS_v1_05";
      operationObjectKey["find"] = "RS_v1_05";
      operationObjectKey["findByCriteria"] = "RS_v1_05";
      operationObjectKey["localFind"] = "RS_v1_05";
      operationObjectKey["init"] = "FTACS_v1_05";
      operationObjectKey["isAlive"] = "FTACS_v1_05";
      operationObjectKey["setStatus"] = "FTACS_v1_05";
      operationObjectKey["kill"] = "FTACS_v1_05";
      operationObjectKey["updateStatus"] = "FTACS_v1_05";
      operationObjectKey["startup"] = "IC_v1_05";
      operationObjectKey["shutdown"] = "IC_v1_05";
      operationObjectKey["getFacet"] = "IC_v1_05";
      operationObjectKey["getFacetByName"] = "IC_v1_05";
      operationObjectKey["getComponentId"] = "IC_v1_05";
    }

    ClientInterceptor::ClientInterceptor(IOP::Codec_ptr pcdr_codec)  
    {
      Openbus::logger->log(INFO, "ClientInterceptor::ClientInterceptor() BEGIN");
      Openbus::logger->indent();
      cdr_codec = pcdr_codec;
      loadOperationObjectKey();
      faultToleranceManager = FaultToleranceManager::getInstance();
      Openbus* bus = Openbus::getInstance();
      Host* ACSHost = new Host;
      ACSHost->name = (char*) bus->hostBus.c_str();
      ACSHost->port = bus->portBus;
      faultToleranceManager->setACSHostInUse(ACSHost);
      if (Openbus::FTConfigFilename) {
        faultToleranceManager->loadConfig(Openbus::FTConfigFilename);
      }
      x = 0;
      Openbus::logger->dedent(INFO, "ClientInterceptor::ClientInterceptor() END");
    }

    ClientInterceptor::~ClientInterceptor() { }

    void ClientInterceptor::send_request(ClientRequestInfo_ptr ri) 
      throw(
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest)
    {
      Openbus::logger->log(INFO, "ClientInterceptor::send_request() BEGIN");
      Openbus::logger->indent();
      stringstream msg;
      char * operation = ri->operation();
      msg << "Method: " << operation;
      Openbus::logger->log(INFO, msg.str());
      free(operation);
      if (credential) {
        stringstream msg;
        msg << "Credential identifier: " << credential->identifier;
        Openbus::logger->log(INFO, msg.str());
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

        CORBA::ULong z;
        stringstream contextData;
        contextData << "Context data: ";
        for ( z = 0; z < sc.context_data.length(); z++ ) {
          contextData <<  (unsigned) sc.context_data[ z ] << " ";
        }
        Openbus::logger->log(INFO, contextData.str());

        ri->add_request_service_context(sc, true);
      }
      Openbus::logger->dedent(INFO, "ClientInterceptor::send_request() END");
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
    {
      Openbus::logger->indent(INFO, 
        "ClientInterceptor::receive_exception() BEGIN");
      const char* received_exception_id = ri->received_exception_id();
      if (!strcmp(received_exception_id, 
             "IDL:omg.org/CORBA/COMM_FAILURE:1.0")
          || !strcmp(received_exception_id, 
             "IDL:omg.org/CORBA/TRANSIENT:1.0")
          || !strcmp(received_exception_id, 
             "IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0")
          ) 
      {
        stringstream out;
        Openbus::logger->log(ERROR, "TRATANDO EXCEÇÂO RECEBIDA DO SERVIDOR!");
        const char* operation = ri->operation();
        const char* objectKey;
        out << "Método: " << operation;
        Openbus::logger->log(INFO, out.str());
        out.str(" ");
        out << "Reply Status: " << ri->reply_status() << endl;
        Openbus::logger->log(INFO, out.str());
        out.str(" ");
        out << "Exceção recebida: " << received_exception_id;
        Openbus::logger->log(INFO, out.str());
        out.str(" ");
     #ifdef OPENBUS_MICO
    #if 0
        CORBA::IOR* ior = ri->target()->_ior();
        CORBA::Long length;
        const CORBA::Octet* octet = ior->get_profile(
          (CORBA::ULong) 0)->objectkey(length);
        string* objectKeyStr = new string((const char*) octet, (size_t) length);
        out << "ObjectKey: " << objectKeyStr->c_str();
        Openbus::logger->log(INFO, out.str());
    #endif
      #else
        itOperationObjectKey = operationObjectKey.find(operation);
        objectKey = itOperationObjectKey->second;
        out << "ObjectKey: " << objectKey;
        Openbus::logger->log(INFO, out.str());
        if (!strcmp(objectKey, "LP_v1_05")
            || !strcmp(objectKey, "ACS_v1_05")
            || !strcmp(objectKey, "RS_v1_05")
            || !strcmp(objectKey, "openbus_v1_05")
            || !strcmp(objectKey, "FTACS_v1_05")
           ) 
        {
          Openbus* bus = Openbus::getInstance();
          Host* newACSHost = faultToleranceManager->updateACSHostInUse();
          bus->hostBus = newACSHost->name;
          bus->portBus = newACSHost->port;

          /* Tempo de espera entre a troca de replica. */
          Openbus::logger->log(INFO, 
            "Aguardando 5s para se conectar a uma nova replica...");
          IT_CurrentThread::sleep(5000);

          bus->createProxyToIAccessControlService();
        /*
        * Falta tratar IC e FT
        */
          if (!strcmp(objectKey, "LP_v1_05")) {
            throw ForwardRequest(bus->iLeaseProvider);
          } else if (!strcmp(objectKey, "ACS_v1_05")) {
            throw ForwardRequest(bus->iAccessControlService);
          } else if (!strcmp(objectKey, "RS_v1_05")) {
            throw ForwardRequest(bus->iRegistryService);
          } else if (!strcmp(objectKey, "openbus_v1_05")) {
            throw ForwardRequest(bus->iComponentAccessControlService);
          } else if (!strcmp(objectKey, "FTACS_v1_05")) {
            throw ForwardRequest(bus->iFaultTolerantService);
          }
        }
      #endif
      }
      Openbus::logger->dedent(INFO, 
        "ClientInterceptor::receive_exception() END");
    }

    void ClientInterceptor::receive_other( ClientRequestInfo_ptr ri ) 
      throw(
        CORBA::SystemException,
        PortableInterceptor::ForwardRequest)
    {
      Openbus::logger->log(INFO, "OUTRA!");
    }
    void ClientInterceptor::destroy() {}
  }
}

