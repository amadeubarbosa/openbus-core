/*
** demo.cpp
*/

#include <openbus.h>
#include <ftc.h>
#include "../IProjectService.h"

#include <iostream>

using namespace openbus;

int main(int argc, char** argv) {
  char PSIDL[256];

  if (argc != 2) {
    std::cout << "Uso: demo <projeto>/<arquivo>" << std::endl;
    return 0;
  }

  char* fileName = argv[1];

  Openbus* openbus = Openbus::getInstance();

  common::CredentialManager* credentialManager = new common::CredentialManager();
  common::ClientInterceptor* clientInterceptor = new common::ClientInterceptor(credentialManager);
  openbus->setClientInterceptor(clientInterceptor);

  services::IAccessControlService* acs = openbus->getACS("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0");
  services::Credential* credential = new services::Credential();
  services::Lease* lease = new services::Lease();

  acs->loginByPassword("tester", "tester", credential, lease);
  credentialManager->setValue(credential);

  services::IRegistryService* rgs = acs->getRegistryService();
  services::PropertyList* propertyList = new services::PropertyList;
  services::Property* property = new services::Property;
  property->name = "facets";
  property->value = new services::PropertyValue;
  property->value->newmember("projectDataService");
  propertyList->newmember(property);
  services::ServiceOfferList* serviceOfferList = rgs->find(propertyList);
  services::ServiceOffer* serviceOffer = serviceOfferList->getmember(0);

  scs::core::IComponent* member = serviceOffer->member;
  const char* OPENBUS_HOME = getenv("OPENBUS_HOME");
  strcpy(PSIDL, OPENBUS_HOME);
  strcat(PSIDL, "/idlpath/project_service.idl");
  member->loadidlfile(PSIDL);

/* Obtendo o serviço de dados. */
  dataService::IDataService* ds = member->getFacet <dataService::IDataService> ("IDL:openbusidl/ds/IDataService:1.0");

/* Chave que representa o arquivo a ser lido */
  dataService::DataKey* dataKey = new dataService::DataKey;
  dataKey->service_id = member->getComponentId();
  dataKey->actual_data_id = fileName;
  projectService::IFile* file = ds->getDataFacet <projectService::IFile> (dataKey, (char*) "IDL:openbusidl/ps/IFile:1.0");

/* Canal de acesso ao arquivo. */
  projectService::DataChannel* dataChannel = file->getDataChannel();
  size_t fileSize = dataChannel->fileSize;

/* Leitura do arquivo */
  ftc* ch = new ftc(dataChannel->fileIdentifier->getmember(0), true, fileSize, dataChannel->host,
      dataChannel->port, dataChannel->accessKey->getmember(0));
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
