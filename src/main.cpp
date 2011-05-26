
#include <tec/core/access_control_servant.hpp>

#include <CORBA.h>

#include <iostream>

int main(int argc, char* argv[])
{
  CORBA::ORB_var orb = CORBA::ORB_init (argc, argv);

  CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
  PortableServer::POA_var poa = PortableServer::POA::_narrow(poa_obj);
  PortableServer::POAManager_var mgr = poa->the_POAManager();

  tec::core::access_control_servant service;

  PortableServer::ObjectId_var id = poa->activate_object(&service);
  CORBA::Object_var obj = poa->id_to_reference(id);
  tecgraf::openbus::core::v1_06::access_control_service
    ::IAccessControlService_var acs = tecgraf::openbus::core
    ::v1_06::access_control_service::IAccessControlService::_narrow(obj);

  CORBA::String_var str = orb->object_to_string (acs.in());
  std::cout << str.in() << std::endl;

  mgr->activate();
  orb->run();
}
