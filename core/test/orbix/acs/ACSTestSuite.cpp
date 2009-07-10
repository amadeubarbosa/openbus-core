/*
* acs/ACSTestSuite.cpp
*/

#ifndef ACS_TESTSUITE_H
#define ACS_TESTSUITE_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cxxtest/TestSuite.h>
#include <openbus.h>
#include <fstream>

using namespace openbus;

class ACSTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* bus;
    openbusidl::acs::IAccessControlService* iAccessControlService;
    services::RegistryService* rgs;
    Credential* credential;
    Credential* credential2;
    Lease lease;
    Lease lease2;
    std::string OPENBUS_SERVER_HOST;
    unsigned short OPENBUS_SERVER_PORT;
    std::string OPENBUS_USERNAME;
    std::string OPENBUS_PASSWORD;

  public:
    ACSTestSuite() {
      try {
        std::string OPENBUS_HOME = getenv("OPENBUS_HOME");
        OPENBUS_HOME += "/core/test/orbix/config.txt";
        std::string temp;
        std::ifstream inFile;
        inFile.open(OPENBUS_HOME.c_str());
        if (!inFile) {
          temp = "Não foi possível carregar o arquivo " + OPENBUS_HOME + ".";
          TS_FAIL(temp);
        }
        while (inFile >> temp) {
          if (temp.compare("OPENBUS_SERVER_HOST") == 0) {
            inFile >> temp; // le o '='
            inFile >> OPENBUS_SERVER_HOST; // le o valor
          }
          if (temp.compare("OPENBUS_SERVER_PORT") == 0) {
            inFile >> temp;
            inFile >> OPENBUS_SERVER_PORT;
          }
          if (temp.compare("OPENBUS_USERNAME") == 0) {
            inFile >> temp;
            inFile >> OPENBUS_USERNAME;
          }
          if (temp.compare("OPENBUS_PASSWORD") == 0) {
            inFile >> temp;
            inFile >> OPENBUS_PASSWORD;
          }
        }
        inFile.close();
        bus = Openbus::getInstance();
        bus->init(
          0, 
          NULL,
          const_cast<char*>(OPENBUS_SERVER_HOST.c_str()), 
          OPENBUS_SERVER_PORT);
        credential2 = new Credential;
      }
      catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    ~ACSTestSuite() {
      try {
        if (bus) {
          if (bus->disconnect())
            delete bus;
        }
        delete credential2;
      }
      catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void setUP() {
    }

    void tearDown() {
    }

    void testInitWithArgcArgv() {
      try {
        delete bus;
        bus = Openbus::getInstance();
        char* argv[] = {
          "exec", 
          "-OpenbusHost", 
          "localhost", 
          "-OpenbusPort", 
          "2089"}; 
        bus->init(5, argv);
#if 0
        bus->init(
          0, 
          NULL,
          const_cast<char*>(OPENBUS_SERVER_HOST.c_str()), 
          OPENBUS_SERVER_PORT);
#endif
        bus->connect(OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str());
      } catch(CORBA::SystemException& e) {
  cout << "entrou" << endl;
        TS_FAIL("** Não foi possível se conectar ao barramento. **");
      }
    }

//   void testConnect() {
//     try {
//       rgs = bus->connect(OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str());
//       TS_ASSERT(rgs);
//       credential = bus->getCredential();
//       TS_ASSERT(credential);
//     }
//     catch (CORBA::COMM_FAILURE& e) {
//       TS_FAIL("** Não foi possível se conectar ao barramento. **");
//     }
//     catch (openbus::LOGIN_FAILURE& e) {
//       TS_FAIL(
//         "** Não foi possível se conectar ao barramento. \
//         Par usuario/senha inválido. **");
//     }
//     catch (const char* errmsg) {
//       TS_FAIL(errmsg);
//     }
//   }
//
//   void testGetACS() {
//     try {
//       iAccessControlService = bus->getAccessControlService();
//       TS_ASSERT(iAccessControlService);
//     }
//     catch (const char* errmsg) {
//       TS_FAIL(errmsg) ;
//     }
//   }
//
//   void testGetRegistryService() {
//     try {
//       delete rgs;
//       rgs = bus->getRegistryService();
//       TS_ASSERT(rgs);
//     }
//     catch (const char* errmsg) {
//       TS_FAIL(errmsg);
//     }
//   }
//
//   void testLogout() {
//     iAccessControlService->loginByPassword(OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str(),
//       credential2, lease2);
//     TS_ASSERT(iAccessControlService->logout(*credential2));
//     credential2->owner = OPENBUS_USERNAME.c_str();
//     credential2->identifier = "dadadsa";
//     credential2->delegate = "";
//     TS_ASSERT(!iAccessControlService->logout(*credential2));
//   }
//
//   void testLoginByCertificate() {
//     const char* certificate = "AccessControlService";
//     openbusidl::OctetSeq* bytes = iAccessControlService->getChallenge(certificate);
//     TS_ASSERT(iAccessControlService->loginByCertificate(certificate, *bytes, credential2, 
//       lease2));
//     delete bytes;
//   }
//
//   void testIsValid() {
//     try {
//       TS_ASSERT(iAccessControlService->isValid(*credential2));
//       credential2->identifier = "123";
//       credential2->owner = OPENBUS_USERNAME.c_str();
//       credential2->delegate = "";
//       TS_ASSERT(!iAccessControlService->isValid(*credential2));
//       iAccessControlService->logout(*credential2);
//       TS_ASSERT(!iAccessControlService->isValid(*credential2));
//     }
//     catch (const char* errmsg) {
//       TS_FAIL(errmsg);
//     }
//   }
//
};

#endif
