#include <iostream>

class IHello {
  public:
    IHello() {}
    ~IHello() {}
    void sayHello() {
      std::cout << "Hello!" << std::endl;
    }
};
