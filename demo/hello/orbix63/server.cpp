/*
** OpenBus Demo - Orbix 6.3
** server.cpp
*/

#include <fstream>
#include <iostream>
#include <omg/orb.hh>
#include <it_ts/thread.h>

#include <openbus.h>

#include "helloS.hh"

using namespace std;

IT_USING_NAMESPACE_STD

openbus::Openbus* bus;

class Hello_impl : virtual public POA_Hello {
  public:
    void sayHello() IT_THROW_DECL((CORBA::SystemException)) {
      cout << endl << "Servant diz: HELLO!" << endl;
      openbus::Credential_var credential = bus->getCredentialIntercepted();
      cout << "Usuário OpenBus que fez a chamada: " << credential->owner.in() << endl;
    };
};

Hello_impl* hello;

int main(int argc, char* argv[]) {
  char* registryId;
  openbus::services::RegistryService* registryService;

  bus = new openbus::Openbus(argc, argv);

/* Se o usuário desejar criar o seu próprio ORB/POA:
*  CORBA::ORB* orb = CORBA::ORB_init(argc, argv);
*  CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
*  PortableServer::POA* poa = PortableServer::POA::_narrow(poa_obj);
*  PortableServer::POAManager_var poa_manager = poa->the_POAManager();
*  poa_manager->activate();
*
*  bus->init(orb, poa);
*/
  bus->init();

/* Conexão com o barramento. */
  try {
    registryService = bus->connect("tester", "tester");
  } catch (openbus::COMMUNICATION_FAILURE& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Falha na comunicacao. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Par usuario/senha inválido. *" << endl;
    exit(-1);
  }

  hello = new Hello_impl;

  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();
  scs::core::IComponentImpl* IComponent = componentBuilder->createComponent("component", 1, "facet", "IDL:Hello:1.0", hello);

/* Definição de uma lista de propriedades que caracteriza o serviço de interesse.
*  O trabalho de criação da lista é facilitado pelo uso da classe PropertyListHelper.
*/
  openbus::services::PropertyListHelper* PropertyListHelper = new openbus::services::PropertyListHelper();
  PropertyListHelper->add("facet", "IHello");

/* Criação de uma *oferta de serviço*. */
  openbus::services::ServiceOffer so;
  so.properties = PropertyListHelper->getPropertyList();
  so.member = IComponent->_this();

/* Registro do serviço no barramento. */
  registryService->Register(so, registryId);
  cout << "Serviço HELLO registrado no OpenBus..." << endl;

  bus->run();

  return 0;
}
