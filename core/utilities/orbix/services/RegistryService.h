/**
* \file RegistryService.h
*
* \brief API do serviço de registro.
*
*/

#ifndef REGISTRYSERVICE_H_
#define REGISTRYSERVICE_H_

#include "../stubs/scs.hh"
#include "../stubs/registry_service.hh"

/**
* \brief Stubs dos serviços básicos.
*/
namespace openbusidl {

/**
* \brief Stub do serviço de registro.
*/
  namespace rs {

  /**
  * \class PropertyValue
  * \brief Representa um valor de uma propriedade. 
  *
  * Este valor é uma sequência de strings, no caso, o valor pode ser único, 
  * sendo representado portanto por somente uma string.
  *
  */

  /**
  * \struct Property
  * \brief Representa uma propriedade que é um par chave/valor.
  *
  * A chave deve ser uma string. O valor pode ser único ou múltiplo, sendo
  * representado através de uma sequência de strings. \see PropertyValue
  *
  */

  /**
  * \class PropertyList
  * \brief Lista de propriedades.
  */

  /**
  * \class ServiceOffer
  * \brief Oferta de serviço
  *
  * Descreve um serviço através de uma lista de propriedades e um componente 
  * SCS. \see PropertyList
  */

  /**
  * \class ServiceOfferList
  * \brief Lista de ofertas de serviço.
  */

  }
}

/**
* \brief openbus
*/
namespace openbus {
/**
* \brief Serviços básicos do Openbus.
*/
  namespace services {

    typedef openbusidl::rs::PropertyList PropertyList;
    typedef openbusidl::rs::ServiceOffer ServiceOffer;
    typedef openbusidl::rs::ServiceOfferList ServiceOfferList;
    typedef openbusidl::rs::ServiceOfferList_var ServiceOfferList_var;

  /**
  * \brief Auxilia na construção de uma lista de propriedades.
  */
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

  /**
  * \brief Representa o serviço de registro. 
  */
    class RegistryService {
      private:
      /**
      * Ponteiro para o serviço de registro. 
      */
        openbusidl::rs::IRegistryService* rgs;
      public:
      
      /**
      * Cria um objeto que representa o serviço de registro.
      *
      * @param[in] _rgs Stub do serviço de registro. 
      */
        RegistryService(openbusidl::rs::IRegistryService* _rgs);

      /**
      * Busca serviços.
      * @param[in] criteria Lista de propriedades que descrevem o serviço 
      *   desejado.
      * @return A lista de ofertas de serviço que atendem aos critérios 
      *   especificados no parâmetro criteria.
      */
        ServiceOfferList* find(PropertyList criteria);

      /**
      * Registra um serviço
      *
      * @param[in] serviceOffer Oferta do serviço a ser registrado no 
      *    barramento.
      * @param[out] registryId Identificação do serviço registrado.
      * @return Se o serviço foi registrado com sucesso, o valor true é 
      *   retornado, caso contrário false é retornado.
      */
        bool Register(
          ServiceOffer serviceOffer,
          char*& registryId);

      /**
      * Remove uma oferta de serviço.
      *
      * @param[in] registryId Identificador do registro da oferta de serviço.
      * @return Se o serviço foi removido com sucesso do barramento,
      *    o valor true é retornado, caso contrário false é retornado.
      */
        bool unregister(char* registryId);
    };
  }
}

#endif
