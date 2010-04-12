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

using namespace tecgraf::openbus::core::v1_05;
using namespace PortableInterceptor;
using namespace std;

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

    #ifdef OPENBUS_MICO
      /*
      * Intervalo em milisegundos de valida��o das credenciais do cache.
      */
        static unsigned long validationTime;

        class CredentialsValidationCallback : 
          public CORBA::DispatcherCallback 
        {
          public:
            CredentialsValidationCallback();
            void callback(CORBA::Dispatcher* dispatcher, Event event);
        };
        friend class ServerInterceptor::CredentialsValidationCallback;

      /*
      * Callback de valida��o do cache de credenciais.
      */
        CredentialsValidationCallback credentialsValidationCallback;

        struct setCredentialCompare {
          bool operator() (
            const access_control_service::Credential& c1,
            const access_control_service::Credential& c2)
          {
            cout << c1.identifier << " " << c2.identifier << endl;
            return (strcmp(c1.identifier, c2.identifier) < 0);
          }
        };

        static set<access_control_service::Credential, setCredentialCompare> 
          credentialsCache;
        static set<access_control_service::Credential>::iterator 
          itCredentialsCache;
    #endif
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
        access_control_service::Credential_var getCredential();
      #ifdef OPENBUS_MICO
        void registerValidationDispatcher();
        void setValidationTime(unsigned long pValidationTime);
        unsigned long getValidationTime();
      #endif
    };
  }
}

#endif