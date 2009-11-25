using System;
using System.Collections.Generic;
using System.Text;
using NUnit.Framework;
using OpenbusAPI.Logger;
using OpenbusAPI;
using openbusidl.rs;

namespace Test_API
{
  [TestFixture]
  class OpenbusTests
  {

    #region Fields

    public String userLogin;
    public String userPassword;
    public String hostName;
    public int hostPort;

    public String testKeyFileName;
    public String acsCertificateFileName;
    public String entityName;

    #endregion

    #region Constructor

    /// <summary>
    /// Inicializa o teste OpenbusTest
    /// </summary>
    public OpenbusTests() {

      this.userLogin = Properties.TestConfig.Default.userLogin;
      this.userPassword = Properties.TestConfig.Default.userPassword;
      this.hostName = Properties.TestConfig.Default.hostName;
      this.hostPort = Properties.TestConfig.Default.hostPort;
      this.testKeyFileName = Properties.TestConfig.Default.testKeyFileName;
      this.acsCertificateFileName = Properties.TestConfig.Default.acsCertificateFileName;
      this.entityName = Properties.TestConfig.Default.entityName;
    }

    #endregion

    #region preparation

    /// <summary>
    /// Este método é chamado antes de todos os testCases.
    /// </summary>
    [TestFixtureSetUp]
    public void BeforeTests() {
      Log.setLogsLevel(Level.WARN);
    }

    /// <summary>
    /// Este método é chamado antes de cada testCase.
    /// </summary>
    [SetUp]
    public void BeforeEachTest() {
      Openbus openbus = Openbus.GetInstance();
      openbus.Init(hostName, hostPort);
    }

    /// <summary>
    /// Este método é chamado depois de cada testCase.
    /// </summary>
    [TearDown]
    public void AfterEachTest() {
      Openbus openbus = Openbus.GetInstance();
      openbus.Destroy();
    }

    #endregion

    #region Tests

    /// <summary>
    /// Testa o connect passando usuário e senha válido
    /// </summary>
    [Test]
    public void ConnectByPassword() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = openbus.Connect(userLogin, userPassword);
      Assert.NotNull(registryService);
      Assert.True(openbus.Disconnect());
    }
    /*
    [Test]
    public void ConnectByPasswordLoginNull() { }

    [Test]
    public void ConnectByPasswordInvalidLogin() { }

    [Test]
    public void ConnectByCertificate() { }

    [Test]
    public void ConnectByCertificateNullKey() { }

    [Test]
    public void ConnectByCertificateNullACSCertificate() { }

    [Test]
    public void ConnectByCredential() { }

    [Test]
    public void ConnectByCredentialNullCredential() { }

    [Test]
    public void IsConnected() { }

    [Test]
    public void Disconnect() { }

    [Test]
    public void GetAccessControlService() { }

    [Test]
    public void GetRegistryService() { }

    [Test]
    public void GetSessionService() { }
    */
    #endregion


  }
}
