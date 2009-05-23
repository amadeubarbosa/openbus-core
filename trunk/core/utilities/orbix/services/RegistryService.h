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
    typedef openbusidl::rs::PropertyList PropertyList;
    typedef openbusidl::rs::ServiceOffer ServiceOffer;
    typedef openbusidl::rs::ServiceOfferList ServiceOfferList;
    typedef openbusidl::rs::ServiceOfferList_var ServiceOfferList_var;

  /* Auxilia na construção de uma lista de propriedades. */
    class PropertyListHelper {
      private:
        openbusidl::rs::PropertyList_var propertyList;
        int numElements;
      public:
        PropertyListHelper();
        ~PropertyListHelper();
        void add(
          const char* key,
          const char* value);
        openbusidl::rs::PropertyList_var getPropertyList();
    };

  /* Representa o serviço de registro. */
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
      *   retorno: Bool indicando se a chamada executou corretamente.
      *   registryId: Identificação do serviço registrado.
      */
        bool Register(
          ServiceOffer serviceOffer,
          char*& registryId);

      /*
      * Remove uma oferta de serviço.
      * Parâmetros de entrada:
      *   identifier: Identificador do registro da oferta de serviço.
      * Parâmetros de saída:
      *   retorno: Bool indicando se a chamada executou corretamente.
      */
        bool unregister(char* registryId);
    };
  }
}

#endif
