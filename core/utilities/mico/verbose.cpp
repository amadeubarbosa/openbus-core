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

void Verbose::indent() {
  numIndent++;
}

void Verbose::indent(string msg) {
  indent();
  print(msg);
  cout << endl;
}

void Verbose::dedent() {
  numIndent--;
}

void Verbose::dedent(string msg) {
  dedent();
  print(msg);
  if (!numIndent) {
    cout << endl;
  }
}

