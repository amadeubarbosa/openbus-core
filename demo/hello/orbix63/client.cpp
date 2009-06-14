/*
** OpenBus Demo - Orbix 6.3
** client.cpp
*/

#include <fstream>
#include <iostream>

#include "stubs/hello.hh"
#include <openbus.h>

using namespace std;

int main(int argc, char* argv[]) {
  openbus::Openbus* bus;
  openbus::services::RegistryService* registryService;

  bus = openbus::Openbus::getInstance();

  bus->init(argc, argv);

/* Conex�o com o barramento. */
  try {
    registryService = bus->connect("tester", "tester");
  } catch (CORBA::SystemException& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Falha na comunicacao. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Par usuario/senha inv�lido. *" << endl;
    exit(-1);
  }

/* Define uma lista de propriedades que caracteriza o servi�o de interesse.
*  O trabalho de cria��o da lista � facilitado pelo uso da classe 
*   PropertyListHelper.
*/
  openbus::services::PropertyListHelper* propertiesHelper = \
    new openbus::services::PropertyListHelper();
  propertiesHelper->add("facet", "IHello");

/* Busca no barramento o servi�o desejado.
*  Uma lista de *ofertas de servi�o* � retornada para o usu�rio.
*  OBS.: Neste demo somente h� uma oferta de servi�o.
*/
  openbus::services::ServiceOfferList_var serviceOfferList = \
    registryService->find(propertiesHelper->getPropertyList());

  CORBA::ULong idx = 0;
  openbus::services::ServiceOffer serviceOffer = serviceOfferList[idx];

  scs::core::IComponent* component = serviceOffer.member;
  CORBA::Object* obj = component->getFacet("IDL:demoidl/hello/IHello:1.0");
  demoidl::hello::IHello* hello = demoidl::hello::IHello::_narrow(obj);
  hello->sayHello();

  bus->disconnect();

  return 0;
}
