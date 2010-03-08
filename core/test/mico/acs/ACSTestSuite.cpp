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
using namespace tecgraf::openbus::core::v1_05;

Openbus* bus;
bool leaseExpiredCallbackOk;

class MyCallback : public Openbus::LeaseExpiredCallback {
  public:
    MyCallback() {}
    void expired() {
      TS_TRACE("Executando leaseExpiredCallback()...");
      leaseExpiredCallbackOk = true;
      delete bus;
      bus = 0;
    }
};

class ACSTestSuite: public CxxTest::TestSuite {
  private:
    access_control_service::IAccessControlService* iAccessControlService;
    registry_service::IRegistryService* rgs;
    access_control_service::Credential* credential;
    access_control_service::Credential* credential2;
    access_control_service::Credential_var trueCredential;
    access_control_service::Lease lease;
    access_control_service::Lease lease2;
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
          temp = "N�o foi poss�vel carregar o arquivo " + OPENBUS_HOME + ".";
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
        credential2 = new access_control_service::Credential;
      }
      catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    ~ACSTestSuite() {
      try {
        if (bus) {
          if (bus->isConnected()) {
            bus->disconnect();
          }
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
        const char* argv[] = {
          "exec", 
          "-OpenbusHost", 
          "localhost", 
          "-OpenbusPort", 
          "2089"};
        bus->init(5, (char**) argv);
        bus->connect(OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str());
        bus->disconnect();
      } catch(CORBA::SystemException& e) {
        TS_FAIL("** N�o foi poss�vel se conectar ao barramento. **");
      }
    }

    void testConnect() {
     try {
        rgs = bus->connect(OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str());
        TS_ASSERT(rgs);
        credential = bus->getCredential();
        TS_ASSERT(credential);
      }
      catch (CORBA::COMM_FAILURE& e) {
        TS_FAIL("** N�o foi poss�vel se conectar ao barramento. **");
      }
      catch (openbus::LOGIN_FAILURE& e) {
        TS_FAIL(
          "** N�o foi poss�vel se conectar ao barramento. \
          Par usuario/senha inv�lido. **");
      }
      catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testIsConnected() {
      TS_ASSERT(bus->isConnected());
      bus->disconnect();
      TS_ASSERT(!bus->isConnected());
      try {
        rgs = bus->connect(OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str());
        TS_ASSERT(rgs);
        credential = bus->getCredential();
        TS_ASSERT(credential);
      }
      catch (CORBA::COMM_FAILURE& e) {
        TS_FAIL("** N�o foi poss�vel se conectar ao barramento. **");
      }
      catch (openbus::LOGIN_FAILURE& e) {
        TS_FAIL(
          "** N�o foi poss�vel se conectar ao barramento. \
          Par usuario/senha inv�lido. **");
      }
      catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testGetORB() {
      TS_ASSERT(bus->getORB());
    }

    void testGetComponentBuilder() {
      TS_ASSERT(bus->getComponentBuilder());
    }

    void testGetACS() {
      try {
        iAccessControlService = bus->getAccessControlService();
        TS_ASSERT(iAccessControlService);
      }
      catch (const char* errmsg) {
        TS_FAIL(errmsg) ;
      }
    }

    void testGetRegistryService() {
      try {
        rgs = 0;
        rgs = bus->getRegistryService();
        TS_ASSERT(rgs);
      }
      catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testIAccessControlService() {
      access_control_service::Credential_var c;
      access_control_service::Lease l;
      iAccessControlService->loginByPassword(OPENBUS_USERNAME.c_str(), 
        OPENBUS_PASSWORD.c_str(),
        c, l);
      TS_ASSERT(iAccessControlService->logout(c));
      credential2->owner = OPENBUS_USERNAME.c_str();
      credential2->identifier = "dadadsa";
      credential2->delegate = "";
      TS_ASSERT(!iAccessControlService->logout(c));
    }

    void testLoginByCertificate() {
      bus->disconnect();
      try {
        rgs = bus->connect(
         "HelloService", 
         "HelloService.key", 
         "AccessControlService.crt"); 
        TS_ASSERT(rgs);
      } catch (CORBA::SystemException& e) {
        TS_FAIL("Falha na comunica��o.");
      } catch (openbus::LOGIN_FAILURE& e) {
        TS_FAIL("Par usu�rio/senha inv�lido.");
      } catch (openbus::SECURITY_EXCEPTION& e) {
        TS_FAIL("e.what()");
      }
    }

    void testIsValid() {
      try {
        iAccessControlService = bus->getAccessControlService();
        TS_ASSERT(iAccessControlService->isValid(*bus->getCredential()));
        credential2->identifier = "123";
        credential2->owner = OPENBUS_USERNAME.c_str();
        credential2->delegate = "";
        TS_ASSERT(!iAccessControlService->isValid(*credential2));
      }
      catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testSetThreadCredential() {
      trueCredential = bus->getCredential();
      access_control_service::Credential wrongCredential;
      wrongCredential.identifier = "00000000";
      wrongCredential.owner = "none";
      wrongCredential.delegate = "";
      bus->setThreadCredential(&wrongCredential);
      iAccessControlService = bus->getAccessControlService();
      try {
        iAccessControlService->isValid(wrongCredential);
        TS_FAIL("A credencial inv�lida inserida n�o foi utilizada. ");
      } catch(CORBA::NO_PERMISSION& e) {
      }
      bus->setThreadCredential(trueCredential);
    }

    void testFinish() {
/*      bus->disconnect();
      bus->finish(true);
      try {
        if (!CORBA::is_nil(bus->getORB())) {
          TS_FAIL("ORB n�o finalizado.");
        }
      } catch(CORBA::SystemException& e) {
      }

      delete bus;
*/
    }

  /*
   * Este caso de teste gera um sleep de 150s.
   */
    void testLeaseExpiredCallback() {
#if 0
      bus->disconnect();
      bus = Openbus::getInstance();
      const char* argv[] = {
        "exec", 
        "-OpenbusHost", 
        "localhost", 
        "-OpenbusPort", 
        "2089",
        "-TimeRenewing",
        "150000"}; 
      bus->init(7, (char**) argv);
      leaseExpiredCallbackOk = false;
      MyCallback myCallback;
      bus->connect(OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str());
      bus->addLeaseExpiredCallback(&myCallback);
      TS_TRACE("Tentativa de renova��o de credencial em at� 150 segundos...");
      bus->run();
      if (!leaseExpiredCallbackOk) {
        TS_FAIL("Fun��o leaseExpiredCallback() n�o foi chamada.");
      }
#endif
    }
};

#endif
