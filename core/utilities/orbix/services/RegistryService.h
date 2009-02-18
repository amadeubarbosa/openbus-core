/*
** RegistryService.h
**
** Header do m�dulo wrapper do servi�o de registro.
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

  /* Auxilia na constru��o de uma lista de propriedades. */
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

  /* Representa o servi�o de registro. */
    class RegistryService {
      private:
      /* Ponteiro para o servi�o de registro. */
        openbusidl::rs::IRegistryService* rgs;
      public:
        RegistryService(openbusidl::rs::IRegistryService* _rgs);

      /*
      * Busca servi�os.
      * criteria: Lista de propriedades que descrevem o servi�o desejado.
      * Retorna uma lista de ofertas de servi�o.
      */
        ServiceOfferList* find(PropertyList criteria);

      /*
      * Registra um servi�o
      * Par�metros de entrada:
      *   serviceOffer: Oferta do servi�o a ser registrado no barramento.
      * Par�metros de sa�da:
      *   retorno: Bool indicando se a chamada executou corretamente.
      *   registryId: Identifica��o do servi�o registrado.
      */
        bool Register(
          ServiceOffer serviceOffer,
          char* registryId);
    };
  }
}

#endif
