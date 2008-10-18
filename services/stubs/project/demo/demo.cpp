/*
** demo.cpp
*/

/*
** Configuracoes
*/
/**************************************************************************************************/
#define USER "tester"     /* Usuario OpenBus. */
#define PASSWORD "tester" /* Senha do usuario OpenBus. */
#define HOST "localhost"  /* Host onde esta o servico de controle de acesso. */
#define PORT "2089"       /* Porta do servico de controle de acesso. */
/**************************************************************************************************/



#include <openbus.h>
#include <ftc.h>
#include "../IProjectService.h"

#include <iostream>
#include <sstream>

using namespace std;
using namespace openbus;

int main(int argc, char** argv) {
  char PSIDL[256];

  if (argc != 2) {
    cout << "Uso: demo <projeto>/<arquivo>" << endl;
    return 0;
  }

  char* fileName = argv[1];

  Openbus* openbus = Openbus::getInstance();

  common::CredentialManager* credentialManager = new common::CredentialManager();
  common::ClientInterceptor* clientInterceptor = new common::ClientInterceptor(credentialManager);
  openbus->setClientInterceptor(clientInterceptor);
  stringstream corbaloc;
  corbaloc << "corbaloc::" << HOST << ":" << PORT << "/ACS";
  services::IAccessControlService* acs = openbus->getACS(corbaloc.str().c_str(), "IDL:openbusidl/acs/IAccessControlService:1.0");

/* Autenticacao no barramento. */
  services::Credential* credential = new services::Credential();
  services::Lease* lease = new services::Lease();
  try {
    if (!acs->loginByPassword(USER, PASSWORD, credential, lease)) {
      throw "Servico de controle de acesso localizado, porem o par usuario/senha nao foi validado.";
    }
  } catch (const char* errmsg) { 
    cout << "** Nao foi possivel se conectar ao barramento." << endl << errmsg << endl; 
    exit(-1);
  }

  credentialManager->setValue(credential);

  services::IRegistryService* rgs = acs->getRegistryService();
  services::PropertyList* propertyList = new services::PropertyList;
  services::Property* property = new services::Property;
  property->name = "facets";
  property->value = new services::PropertyValue;
  property->value->newmember("projectDataService");
  propertyList->newmember(property);
  services::ServiceOfferList* serviceOfferList = rgs->find(propertyList);
  if (!serviceOfferList) {
    cout << "** Nenhum servico de projetos foi encontrado no barramento." << endl;
    exit(-1);
  }
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
  projectService::IFile* file;
  projectService::DataChannel* dataChannel;
  file = ds->getDataFacet <projectService::IFile> (dataKey, (char*) "IDL:openbusidl/ps/IFile:1.0");
  if (!file) {
    cout << "** Arquivo nao encontrado." << endl;
    exit(-1);
  }
/* Canal de acesso ao arquivo. */
  dataChannel = file->getDataChannel();
  size_t fileSize = dataChannel->fileSize;

/* Leitura do arquivo */
  ftc* ch = new ftc(dataChannel->fileIdentifier->getmember(0), true, fileSize, dataChannel->host,
      dataChannel->port, dataChannel->accessKey->getmember(0));
  try {
    ch->open(true);
  } catch (const char* errmsg) { 
    cout << "** Erro ao abrir arquivo: " << errmsg << endl; 
    exit(-1);
  }
  char* content = new char[fileSize];
  ch->read(content, fileSize, 0);
  cout << "Eu li:";
  for (size_t i = 0; i < fileSize; i++) {
    cout << content[i];
  }
  cout << endl;
  ch->close();

  return 0;
}

