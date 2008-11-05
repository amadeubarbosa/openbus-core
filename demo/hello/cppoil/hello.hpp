#include <iostream>
#include <openbus.h>

using namespace openbus;

class IHello {
  public:
    IHello() {}
    ~IHello() {}
    void sayHello() {
      services::Credential* credential = Openbus::getInstance()->getServerInterceptor()->getCredential();
      std::cout << "Hello!" << std::endl << "Owner: " << credential->owner << std::endl;
    }
};
