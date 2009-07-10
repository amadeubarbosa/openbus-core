/**
* \file verbose.h
*/

#ifndef VERBOSE_H_
#define VERBOSE_H_

#include <string>
#include <sstream>

using namespace std;

class Verbose {
  private:
    short numIndent;
  public:
    Verbose();
    ~Verbose();

    void indent();
    void indent(string msg);
    void dedent();
    void dedent(string msg);
    void print(string msg);
    void println(string msg);
};

#endif

