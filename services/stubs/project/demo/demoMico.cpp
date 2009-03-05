/*
** demoMico.cpp
*/

#include <openbus.h>
#include <ftc.h>

#include "stubs/project_service.h"

#include <iostream>

using namespace std;
using namespace openbusidl::acs;
using namespace openbusidl::rs;
using namespace openbus::common;

int main(int argc, char** argv) {
  if (argc != 2) {
    std::cout << "Uso: demo <projeto>/<arquivo>" << std::endl;
    return 0;
  }

  char* fileName = argv[1];

  Lease lease = 0;
  Credential_var credential;
  CredentialManager credentialManager;

  ORBInitializerImpl* ini = new ORBInitializerImpl(&credentialManager);
  PortableInterceptor::register_orb_initializer(ini);

  CORBA::ORB_var orb = CORBA::ORB_init(argc, argv);
  CORBA::Object_var poaobj = orb->resolve_initial_references ("RootPOA");
  PortableServer::POA_var poa = PortableServer::POA::_narrow (poaobj);
  PortableServer::POAManager_var mgr = poa->the_POAManager();

  CORBA::Object_var obj = orb->string_to_object("corbaloc::localhost:2089/ACS");
  IAccessControlService_var acs = IAccessControlService::_narrow(obj);

  bool status = acs->loginByPassword("tester", "tester", credential, lease);
  if (status) {
    credentialManager.setValue(credential);
    cout << endl << "CLIENT" << endl;
    cout << "Login efetuado no Openbus." << endl;
    cout << "entityName = " << credential->entityName.in() << endl;
    cout << "identifier = " << credential->identifier.in() << endl;
  } else {
    return -1;
  }

  IRegistryService_var rgs = acs->getRegistryService();
  PropertyList_var p = new PropertyList(1);
  p->length(1);
  ServiceOfferList_var soList = new ServiceOfferList(1);
  soList->length(1);
  Property_var property = new Property;
  property->name = "facets";
  PropertyValue_var propertyValue = new PropertyValue(1);
  propertyValue->length(1);
  propertyValue[(MICO_ULong) 0] = "projectDataService";
  property->value = propertyValue;
  p[(MICO_ULong) 0] = property;
  soList = rgs->find(p);
  ServiceOffer so;
  so = soList[(MICO_ULong) 0];
  ::scs::core::IComponent_var member;
  member = so.member;
  obj = member->getFacet("IDL:openbusidl/ds/IDataService:1.0");
  openbusidl::ds::IDataService* ds = openbusidl::ds::IDataService::_narrow(obj);

  openbusidl::ds::DataKey* dataKey = new openbusidl::ds::DataKey;
  dataKey->service_id = *member->getComponentId();
  dataKey->actual_data_id = fileName;

  openbusidl::ds::IDataEntry* dataEntry = ds->getDataFacet(*dataKey, (char*) "IDL:openbusidl/ps/IFile:1.0");
  openbusidl::ps::IFile_ptr file = openbusidl::ps::IFile::_narrow(dataEntry);
  openbusidl::ps::DataChannel* dataChannel = file->getDataChannel();
  size_t fileSize = dataChannel->fileSize;

/* Leitura do arquivo */
  ftc* ch = new ftc((const char*) dataChannel->fileIdentifier.get_buffer(), true, fileSize, dataChannel->host,
      dataChannel->port, (const char*) dataChannel->accessKey.get_buffer());
  ch->open(true);
  char* content = new char[fileSize];
  ch->read(content, fileSize, 0);
  std::cout << "Eu li:";
  for (size_t i = 0; i < fileSize; i++) {
    std::cout << content[i];
  }
  std::cout << std::endl;
  ch->close();

  return 0;
}
