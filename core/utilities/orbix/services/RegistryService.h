/*
** RegistryService.h
**
** Header do módulo wrapper do serviço de registro.
**
*/

#ifndef REGISTRYSERVICE_H_
#define REGISTRYSERVICE_H_

#include "../stubs/scs.hh"
#include "../stubs/registry_service.hh"

namespace openbus {
  namespace services {
//     typedef char** PropertyList;
    typedef openbusidl::rs::PropertyList PropertyList;
    typedef openbusidl::rs::ServiceOffer ServiceOffer;
    typedef openbusidl::rs::ServiceOfferList ServiceOfferList;

    class RegistryService {
      private:
      /* Ponteiro para o serviço de registro. */
        openbusidl::rs::IRegistryService* rgs;
      public:
        RegistryService(openbusidl::rs::IRegistryService* _rgs);

      /*
      * Busca serviços.
      * criteria: Lista de propriedades que descrevem o serviço desejado.
      * Retorna uma lista de ofertas de serviço.
      */
        ServiceOfferList* find(PropertyList criteria);

      /*
      * Registra um serviço
      * Parâmetros de entrada:
      *   serviceOffer: Oferta do serviço a ser registrado no barramento.
      * Parâmetros de saída:
      *   registryId: Identificação do serviço registrado.
      */
        void Register(ServiceOffer serviceOffer, char* registryId);

         void Register(PropertyList propertyList, scs::core::IComponent* iComponent, char* registryId);
    };
  }
}

#endif
