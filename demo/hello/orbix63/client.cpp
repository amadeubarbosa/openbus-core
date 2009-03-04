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

  bus = new openbus::Openbus(argc, argv);

/* Se o usu�rio desejar criar o seu pr�prio ORB/POA:
*  CORBA::ORB* orb = CORBA::ORB_init(argc, argv);
*  CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
*  PortableServer::POA* poa = PortableServer::POA::_narrow(poa_obj);
*  PortableServer::POAManager_var poa_manager = poa->the_POAManager();
*  poa_manager->activate();
*
*  bus->init(orb, poa);
*/
  bus->init();

/* Conex�o com o barramento. */
  try {
    registryService = bus->connect("tester", "tester");
  } catch (openbus::COMMUNICATION_FAILURE& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Falha na comunicacao. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Par usuario/senha inv�lido. *" << endl;
    exit(-1);
  }

/* Define uma lista de propriedades que caracteriza o servi�o de interesse.
*  O trabalho de cria��o da lista � facilitado pelo uso da classe PropertyListHelper.
*/
  openbus::services::PropertyListHelper* propertiesHelper = new openbus::services::PropertyListHelper();
  propertiesHelper->add("facet", "IHello");

/* Busca no barramento o servi�o desejado.
*  Uma lista de *ofertas de servi�o* � retornada para o usu�rio.
*  OBS.: Neste demo somente h� uma oferta de servi�o.
*/
  openbus::services::ServiceOfferList_var soList = registryService->find(propertiesHelper->getPropertyList());

  CORBA::ULong idx = 0;
  openbus::services::ServiceOffer so = soList[idx];

  scs::core::IComponent* component = so.member;
  CORBA::Object* obj = component->getFacet("IDL:Hello:1.0");
  Hello* hello = Hello::_narrow(obj);
  hello->sayHello();

  bus->disconnect();

  return 0;
}
