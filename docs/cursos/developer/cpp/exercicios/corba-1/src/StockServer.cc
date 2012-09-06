#include <fstream>
#include <iostream>
#include <map>
#include <CORBA.h>

#include "StockMarket.h"

class StockServer_impl : public POA_StockMarket::StockServer {
public:
  StockServer_impl(const std::map<std::string, float> &m) 
    : _stocks(m) { }

  CORBA::Float getStockValue(const char *symbol) {
    std::map<std::string, float>::const_iterator it = _stocks.find(std::string(symbol));
    if (it != _stocks.end()) 
      return it->second;
    return 0;
  }

  StockMarket::StockSymbolList * getStockSymbols() {
    StockMarket::StockSymbolList_var l = new StockMarket::StockSymbolList;
    l->length(_stocks.size());
    CORBA::ULong i = 0;
    for (std::map<std::string, float>::const_iterator it = _stocks.begin(); it != _stocks.end(); 
         ++it, ++i) 
      l[i] = CORBA::string_dup(it->first.c_str());
    return l._retn();
  }
private:
  std::map<std::string, float> _stocks;
};

int main(int argc, char **argv) {
  CORBA::ORB_var orb = CORBA::ORB_init(argc, argv);
  
  CORBA::Object_var o = orb->resolve_initial_references("RootPOA");
  PortableServer::POA_var poa = PortableServer::POA::_narrow(o);

  PortableServer::POAManager_var m = poa->the_POAManager();
  m->activate();

  std::map<std::string, float> stocks;
  stocks["VAL"] = 7.56;
  stocks["FIN"] = 10.34;
  stocks["PET"] = 8.67;

  StockServer_impl s(stocks);
  std::ofstream ior(".ior");
  if (!ior) {
    std::cout << "erro ao tentar criar o arquivo '.ior'" << std::endl;
    return -1;
  }
  ior << orb->object_to_string(s._this());
  ior.close();

  orb->run();

  return 0;
}
