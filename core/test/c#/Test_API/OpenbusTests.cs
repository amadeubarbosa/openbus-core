using System;
using NUnit.Framework;
using OpenbusAPI.Logger;
using OpenbusAPI;
using openbusidl.rs;
using OpenbusAPI.Exception;
using OpenbusAPI.Security;
using System.Security.Cryptography.X509Certificates;

namespace Test_API
{
  [TestFixture]
  class OpenbusTests
  {
    #region Fields

    private String userLogin;
    private String userPassword;
    private String hostName;
    private int hostPort;

    private String testKeyFileName;
    private String acsCertificateFileName;
    private String entityName;

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
    /// Testa o connect passando usuário e senha válido.
    /// </summary>
    [Test]
    public void ConnectByPassword() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = openbus.Connect(userLogin, userPassword);
      Assert.NotNull(registryService);
      Assert.True(openbus.Disconnect());
    }

    /// <summary>
    /// Testa o connect passando login null.
    /// </summary>
    [Test]
    [ExpectedException(typeof(ArgumentException))]
    public void ConnectByPassword_NullLogin() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = openbus.Connect(null, userPassword);
      Assert.NotNull(registryService);
      Assert.True(openbus.Disconnect());
    }

    /// <summary>
    /// Testa o connect passando password null.
    /// </summary>
    [Test]
    [ExpectedException(typeof(ArgumentException))]
    public void ConnectByPassword_NullPassword() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = openbus.Connect(userLogin, null);
      Assert.NotNull(registryService);
      Assert.True(openbus.Disconnect());
    }

    /// <summary>
    /// Testa o connect passando usuário inválido.
    /// </summary>
    [Test]
    [ExpectedException(typeof(ACSLoginFailureException))]
    public void ConnectByPassword_InvalidLogin() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = openbus.Connect("null", "null");
      Assert.NotNull(registryService);
      Assert.True(openbus.Disconnect());
    }

    /// <summary>
    /// Testa o connect passando o certificado.
    /// </summary>
    [Test]
    public void ConnectByCertificate() {
      Openbus openbus = Openbus.GetInstance();
      String xmlPrivateKey = Crypto.ReadPrivateKey(testKeyFileName);
      Assert.IsNotEmpty(xmlPrivateKey);

      X509Certificate2 acsCertificate =
        Crypto.ReadCertificate(acsCertificateFileName);
      Assert.IsNotNull(acsCertificate);

      IRegistryService registryService =
        openbus.Connect(entityName, xmlPrivateKey, acsCertificate);
      Assert.NotNull(registryService);
      Assert.True(openbus.Disconnect());
    }

    [Test]
    [ExpectedException(typeof(ACSLoginFailureException))]
    public void ConnectByCertificate_InvalidEntityName() {
      Openbus openbus = Openbus.GetInstance();
      String xmlPrivateKey = Crypto.ReadPrivateKey(testKeyFileName);
      Assert.IsNotEmpty(xmlPrivateKey);

      X509Certificate2 acsCertificate =
        Crypto.ReadCertificate(acsCertificateFileName);
      Assert.IsNotNull(acsCertificate);

      IRegistryService registryService =
        openbus.Connect("null", xmlPrivateKey, acsCertificate);
    }

    [Test]
    [ExpectedException(typeof(ArgumentException))]
    public void ConnectByCertificateNullKey() {
      Openbus openbus = Openbus.GetInstance();

      X509Certificate2 acsCertificate =
        Crypto.ReadCertificate(acsCertificateFileName);
      Assert.IsNotNull(acsCertificate);

      IRegistryService registryService =
        openbus.Connect(entityName, null, acsCertificate);
      Assert.NotNull(registryService);
      Assert.True(openbus.Disconnect());
    }

    [Test]
    [ExpectedException(typeof(ArgumentException))]
    public void ConnectByCertificateNullACSCertificate() {
      Openbus openbus = Openbus.GetInstance();
      String xmlPrivateKey = Crypto.ReadPrivateKey(testKeyFileName);
      Assert.IsNotEmpty(xmlPrivateKey);

      IRegistryService registryService =
        openbus.Connect(entityName, xmlPrivateKey, null);
      Assert.NotNull(registryService);
      Assert.True(openbus.Disconnect());
    }
    /*
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
