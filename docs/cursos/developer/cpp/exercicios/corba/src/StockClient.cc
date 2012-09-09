#include <fstream>
#include <iostream>
#include <CORBA.h>

#include "StockMarket.h"

int main(int argc, char **argv) {
  std::ifstream ior(".ior");
  std::string sior;
  ior >> sior;
  ior.close();

  CORBA::ORB_var orb = CORBA::ORB_init(argc, argv);
  CORBA::Object_var o = orb->string_to_object(sior.c_str());

  StockMarket::StockServer * stockServer = StockMarket::StockServer::_narrow(o);
  if (CORBA::is_nil(o)) {
    std::cout << "error: narrow()." << std::endl;
    return -1;
  }
    

  StockMarket::StockSymbolList_var l = stockServer->getStockSymbols();
  for (CORBA::ULong i = 0; i < l->length(); ++i)
    std::cout << l[i] << ": " << stockServer->getStockValue(l[i]) << std::endl;

  return 0;
}
