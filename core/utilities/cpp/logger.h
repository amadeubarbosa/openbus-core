/**
* \file logger.h
*/

#ifndef LOGGER_H_
#define LOGGER_H_

#include <fstream>
#include <string>
#include <sstream>
#include <map>

#define ENUM_TO_STR(enumValue) #enumValue

using namespace std;

namespace logger {

/**
* \brief Nível de mensagem.
* O nível ALL e OFF possuem um comportamento distinto 
* perante os demais. ALL representa  todos  os demais 
* níveis com exceção do OFF. O  nível  OFF representa
* a ausência de todos os demais níveis com exceção do 
* ALL.
*/
  enum Level {
    ALL,
    ERROR,
    INFO,
    WARNING,
    OFF
  };

/**
* \brief Representa um objeto do tipo Logger  a   ser 
* utilizado como mecanismo de log.
*/ 
  class Logger {
    private:
    /**
    * Relação entre os níveis como elementos de enumeração
    * com as representações dos níveis em strings.
    */
      static const char* levelStr[];

    /**
    * Singleton do Logger.
    */
      static Logger* logger;

    /**
    * Mapeamento que descreve quais níveis estão ativados.
    */
      map<Level, bool> levelFlag; 

    /**
    * Contador de edentação utilizado para se gerar   uma
    * saída hierárquica conforme a pilha de chamadas.
    */
      short numIndent;

    /**
    * Path relativo ou absoluto do arquivo  de  saída  do
    * Logger.
    */
      char* filename;
      ostream* output;

      Logger();
      ~Logger();
    public:
    /**
    * Fornece a única instância do Logger.
    *
    * @return Logger
    */
      static Logger* getInstance();
   
    /**
    * Define a saída do logger.
    *
    * O padrão é saída padrão stdout.
    *
    * @param[in] filename Caminho relativo ou absoluto do arquivo de saída 
    *   do logger. O valor 0 (NULL) representa a saída padrão stdout,
    */
      void setOutput(char* filename);

    /**
    * Ativa ou desativa um determinado nível de mensagem.
    *
    * Se o nível está desativado, a chamada a este método ativará o mesmo, 
    * e vice-versa.
    *
    * @param [in] Nível de mensagem.
    */
      void setLevel(Level level);

    /**
    * Informa se um nível está ativo ou não.
    *
    * @return True se o nível está ativo, caso contrário retorna false.
    */
      bool getLevel(Level level);

    /**
    * Registra uma mensagem utilizando um determinado nível.
    *
    * @param [in] level Nível de mensagem.
    * @param [in] message Mensagem.
    */
      void log(Level level, string message);

    /**
    * Edenta em um nível as mensagens seguintes.
    *
    * Abre-se um novo escopo para as mensagens seguintes a esta chamada.
    */
      void indent(); 

    /**
    * Edenta em um nível as mensagens seguintes.
    *
    * Registra uma mensagem e abre um novo escopo para as mensagens 
    * seguintes a esta chamada.
    *
    * @param [in] level Nível de mensagem.
    * @param [in] message Mensagem.
    */
      void indent(Level level, string message);

    /**
    * Desfaz uma edentação.
    *
    * Fecha o escopo atual de mensagens.
    */
      void dedent();

    /**
    * Desfaz uma edentação.
    *
    * Fecha o escopo atual de mensagens e logo após registra uma 
    * mensagem.
    *
    * @param [in] level Nível de mensagem.
    * @param [in] message Mensagem.
    */
      void dedent(Level level, string message);
  };
}

#endif

