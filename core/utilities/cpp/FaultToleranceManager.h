/*
** FaultToleranceManager.h
*/

#ifndef FAULTTOLERANCEMANAGER_H_
#define FAULTTOLERANCEMANAGER_H_

#include <list>

namespace openbus {

  struct Host {
    char* name;
    unsigned short port;
  };
      
  class FaultToleranceManager {
    private:
    /**
    * Instancia singleton da classe FaultToleranceManager.
    */
      static FaultToleranceManager* faultToleranceManager;

    /**
    * Maquina que contem a replica que esta sendo usada.
    */
      Host* acsHostInUse;

    /**
    * Lista das replicas disponiveis do ACS.
    */
      std::list<Host*> acsHosts;
      std::list<Host*>::iterator itACSHosts;

      FaultToleranceManager();

    public:
      ~FaultToleranceManager();

    /**
    * Fornece a unica instancia do barramento.
    *
    * @return FaultToleranceManager
    */
      static FaultToleranceManager* getInstance();

    /**
    * Carrega o arquivo de configuracao das replicas.
    *
    * @param[in] filename Nome do arquivo de configuracao.
    */
      void loadConfig(char* filename);

    /**
    * Define a maquina em que esta o ACS em uso.
    */
      void setACSHostInUse(Host* host);

    /**
    * Substitui a referência do ACS atual por uma outra replica 
    * do ACS que esteja na lista de replicas.
    */
      Host* updateACSHostInUse();
  };
}

#endif

