/*
** AccessControlService.h
**
** Header do módulo wrapper do serviço de acesso.
**
*/

#ifndef ACCESSCONTROLSERVICE_H_
#define ACCESSCONTROLSERVICE_H_

#include "RegistryService.h"

#include <omg/orb.hh>
#include "../stubs/access_control_service.hh"
#include "../stubs/registry_service.hh"

namespace openbus {
  namespace services {
    class AccessControlService {
      private:
      /* Ponteiro para ORB utilizado. */
        CORBA::ORB* orb;
      /* Ponteiro para o serviço de acesso. */
        openbusidl::acs::IAccessControlService* iAccessControlService;
      public:
      /*
      * host: host do barramento.
      * port: porta do barramento.
      * _orb: ORB utilizado pelo cliente.
      */
        AccessControlService(const char* host, short unsigned int port, CORBA::ORB* _orb) throw (CORBA::SystemException);

      /*
      * Retorna um ponteiro para o serviço de registro.
      */
        RegistryService* getRegistryService();

      /*
      * Renova uma credencial.
      * credential: Credencial a ser renovada.
      * lease: Tempo de renovação da credencial.
      */
        bool renewLease(openbusidl::acs::Credential credential, openbusidl::acs::Lease lease);

      /*
      * Efetua logout de uma determinada credencial.
      * credential: Credencial que representa o usuário a ser deslogado.
      */
        bool logout(openbusidl::acs::Credential credential);

      /*
      * Retorna o stub que representa o serviço de acesso, ou seja, um ponteiro para o serviço de acesso.
      */
        openbusidl::acs::IAccessControlService* getStub();
    };
  }
}

#endif
