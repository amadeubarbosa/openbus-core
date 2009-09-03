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
#define PORT 2089         /* Porta do servico de controle de acesso. */
/**************************************************************************************************/



#include <openbus.h>
#include <ftc.h>
#include "../IProjectService.h"

#include <iostream>
#include <string>

using namespace std;
using namespace openbus;

int main(int argc, char** argv) {
  if (argc != 2) {
    cout << "Uso: demo <projeto>/<arquivo>" << endl;
    return 0;
  }

  char* fileName = argv[1];

  Openbus* openbus = Openbus::getInstance();

/* Conexao com o barramento. */
  services::Credential* credential = new services::Credential();
  services::Lease* lease = new services::Lease();
  services::IAccessControlService* acs;
  try {
    acs = openbus->connect(HOST, (unsigned short) PORT, USER, PASSWORD, credential, lease);
  } catch (const char* errmsg) {
    cout << "** Nao foi possivel se conectar ao barramento." << endl << errmsg << endl; 
    exit(-1);
  }

/* Adquirindo o servico de registro. */
  services::IRegistryService* rgs = acs->getRegistryService();

/* Procurando o servico de projetos do CSBase no barramento. */
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
  string PSIDLPath(getenv("OPENBUS_HOME"));
  PSIDLPath += "/idlpath/project_service.idl";
  member->loadidlfile(PSIDLPath.c_str());

/* Obtendo o servi�o de dados. */
  dataService::IDataService* ds = member->getFacet <dataService::IDataService> ("IDL:openbusidl/ds/IDataService:1.0");

/* Chave que representa o arquivo a ser lido */
  dataService::DataKey* dataKey = new dataService::DataKey;
  dataKey->service_id = member->getComponentId();
  dataKey->actual_data_id = fileName;
  projectService::IFile* file;
  file = ds->getDataFacet <projectService::IFile> (dataKey, (char*) "IDL:openbusidl/ps/IFile:1.0");
  if (!file) {
    cout << "** Arquivo nao encontrado." << endl;
    exit(-1);
  }
/* Canal de acesso ao arquivo. */
  dataService::DataChannel* dataChannel = file->getDataChannel();
  size_t dataSize = dataChannel->dataSize;

/* Leitura do arquivo */
  ftc* ch = new ftc(dataChannel->dataIdentifier->getmember(0), true, dataSize, dataChannel->host,
      dataChannel->port, dataChannel->accessKey->getmember(0));
  try {
    ch->open(true);
  } catch (const char* errmsg) { 
    cout << "** Erro ao abrir arquivo: " << errmsg << endl; 
    exit(-1);
  }
  char* content = new char[dataSize];
  ch->read(content, dataSize, 0);
  cout << "Eu li:";
  for (size_t i = 0; i < dataSize; i++) {
    cout << content[i];
  }
  cout << endl;
  ch->close();

  return 0;
}
