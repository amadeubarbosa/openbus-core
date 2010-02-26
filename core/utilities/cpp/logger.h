/**
* \file logger.h
*/

#ifndef LOGGER_H_
#define LOGGER_H_

#include <string>
#include <sstream>
#include <map>

#define ENUM_TO_STR(enumValue) #enumValue

using namespace std;

namespace logger {
  enum Level {
    ERROR,
    INFO,
    WARNING
  };

  class Logger {
    private:
      static const char* levelStr[];
      short numIndent;
      static Logger* logger;
      Logger();
      ~Logger();
    public:
      static Logger* getInstance();
   
      void log(Level level, string message);
      void indent(); 
      void indent(Level level, string msg);
      void dedent();
      void dedent(Level level, string msg);
  };
}

#endif

