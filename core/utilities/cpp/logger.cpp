/**
* \file logger.cpp
*/

#include "logger.h"

#include <iostream>

using namespace std;
using namespace logger;

const char* Logger::levelStr[] = {
  ENUM_TO_STR(ALL),
  ENUM_TO_STR(ERROR),
  ENUM_TO_STR(INFO),
  ENUM_TO_STR(WARNING)
  ENUM_TO_STR(OFF),
};

Logger* Logger::logger = 0;

Logger::Logger() {
  numIndent          = 0;
  levelFlag[ALL]     = false;
  levelFlag[ERROR]   = false;
  levelFlag[INFO]    = false;
  levelFlag[WARNING] = false;
  levelFlag[OFF]     = true;
  this->filename     = 0;
  output = &cout;
}

Logger::~Logger() {
  if (filename) {
    ofstream* stream = (ofstream*) output;
    stream->flush();
    stream->close();
  }
}

Logger* Logger::getInstance() {
  if (!logger) {
    logger = new Logger;
  }
  return logger;
}

void Logger::setOutput(char* filename) {
  this->filename = filename;
  if (filename) {
    output = new ofstream(filename);
  } else {
    output = &cout;
  }
}

void Logger::setLevel(Level level) {
  levelFlag[level] = true;
  if (level != OFF) {
    levelFlag[OFF] = false;
  }
}

bool Logger::getLevel(Level level) {
  return levelFlag[level];
}

void Logger::log(Level level, string msg) {
  if (levelFlag[ALL] || (!levelFlag[OFF] && levelFlag[level])) {
    stringstream msgStream;
    stringstream spaces;
    for (short x = 0; x < numIndent; x++) {
      spaces << "  ";
    }
    msgStream << "[" << levelStr[level] << "] " << msg;
    msg = msgStream.str();
    size_t msgLength = msg.length();
    if (msgLength > 80) {
      for (size_t msgSize = msgLength, x = 0; 
        msgSize > 80; 
        msgSize = msgSize - 80, x = x + 80) 
      {
        *output << spaces.str() << msgStream.str().substr(x, 80) << endl;
      }
    } else {
      *output << spaces.str() << msgStream.str() << endl;
    }
    output->flush();
  }
}

void Logger::indent() {
  numIndent++;
}

void Logger::indent(Level level, string message) {
  log(level, message);
  indent();
  *output << endl;
}

void Logger::dedent() {
  numIndent--;
}

void Logger::dedent(Level level, string message) {
  dedent();
  log(level, message);
  if (!numIndent) {
    *output << endl;
  }
}

