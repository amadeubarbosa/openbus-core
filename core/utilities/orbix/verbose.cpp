/**
* \file verbose.cpp
*/

#include "verbose.h"

#include <iostream>

Verbose::Verbose() {
  numIndent = 0;
}

Verbose::~Verbose() {

}

void Verbose::indent() {
  numIndent++;
}

void Verbose::dedent() {
  numIndent--;
}

void Verbose::print(string msg) {
  stringstream msgStream;
  stringstream spaces;
  for (short x = 0; x < numIndent; x++) {
    spaces << "  ";
  }
  msgStream << "[" << msg << "]";
  msg = msgStream.str();
  size_t msgLength = msg.length();
  if (msgLength > 80) {
    for (size_t msgSize = msgLength, x = 0; 
         msgSize > 80; 
         msgSize = msgSize - 80, x = x + 80) 
    {
      cout << spaces.str() << msgStream.str().substr(x, 80) << endl;
    }
  } else {
    cout << spaces.str() << msgStream.str() << endl;
  }
}

