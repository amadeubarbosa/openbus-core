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
    ALL,
    ERROR,
    INFO,
    WARNING,
    OFF
  };

  class Logger {
    private:
      static const char* levelStr[];
      static Logger* logger;
      map<Level, bool> levelFlag; 
      short numIndent;
      Logger();
      ~Logger();
    public:
      static Logger* getInstance();
   
      void setLevel(Level level);
      void log(Level level, string message);
      void indent(); 
      void indent(Level level, string msg);
      void dedent();
      void dedent(Level level, string msg);
  };
}

#endif

