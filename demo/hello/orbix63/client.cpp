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

  cout << "Conectando no barramento..." << endl;

/* Conexão com o barramento. */
  try {
    registryService = bus->connect("tester", "tester");
  } catch (CORBA::SystemException& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Falha na comunicacao. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Par usuario/senha inválido. *" << endl;
    exit(-1);
  }

  cout << "Conexão com o barramento estabelecida com sucesso!" << endl;

/* Define a lista de facetas que caracteriza o serviço implementa.
*  O trabalho de criação da lista é facilitado pelo uso da classe 
*  FacetListHelper.
*/
  openbus::services::FacetListHelper* facetListHelper =
    new openbus::services::FacetListHelper();
  facetListHelper->add("IHello");

/* Busca no barramento o serviço desejado.
*  Uma lista de *ofertas de serviço* é retornada para o usuário.
*  OBS.: Neste demo somente há uma oferta de serviço.
*/
  openbus::services::ServiceOfferList_var serviceOfferList =
    registryService->find(facetListHelper->getFacetList());
  delete facetListHelper;

  CORBA::ULong idx = 0;
  openbus::services::ServiceOffer serviceOffer = serviceOfferList[idx];

  scs::core::IComponent_var component = serviceOffer.member;
  CORBA::Object_var obj = component->getFacet("IDL:demoidl/hello/IHello:1.0");
  demoidl::hello::IHello_var hello = demoidl::hello::IHello::_narrow(obj);

  cout << "Fazendo chamada remota sayHello()..." << endl;

  hello->sayHello();

  cout << "Desconectando-se do barramento..." << endl;

  bus->disconnect();
  delete bus;

  return 0;
}

