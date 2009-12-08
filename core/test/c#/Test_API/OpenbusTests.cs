using System;
using NUnit.Framework;
using OpenbusAPI.Logger;
using OpenbusAPI;
using openbusidl.acs;
using openbusidl.rs;
using OpenbusAPI.Exception;
using OpenbusAPI.Security;
using System.Security.Cryptography.X509Certificates;

namespace Test_API
{
  /// <summary>
  /// Classe responsável por testar a API Openbus.
  /// </summary>
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

    #region Preparation

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

    #region API

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
      IRegistryService registryService = null;
      try {
        registryService = openbus.Connect(null, userPassword);
      }
      finally {
        Assert.Null(registryService);
        Assert.False(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa o connect passando password null.
    /// </summary>
    [Test]
    [ExpectedException(typeof(ArgumentException))]
    public void ConnectByPassword_NullPassword() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = null;
      try {
        registryService = openbus.Connect(userLogin, null);
      }
      finally {
        Assert.Null(registryService);
        Assert.False(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa o connect passando usuário inválido.
    /// </summary>
    [Test]
    [ExpectedException(typeof(ACSLoginFailureException))]
    public void ConnectByPassword_InvalidLogin() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = null;
      try {
        registryService = openbus.Connect("null", "null");
      }
      finally {
        Assert.Null(registryService);
        Assert.False(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa conectar duas vezes ao barramento utilizando o método connect 
    /// por usuário e senha.
    /// </summary>
    [Test]
    [ExpectedException(typeof(ACSLoginFailureException))]
    public void ConnectByPassword_Twice() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = openbus.Connect(userLogin, userPassword);
      Assert.NotNull(registryService);
      registryService = null;
      try {
        openbus.Connect(userLogin, userPassword);
      }
      finally {
        Assert.Null(registryService);
        Assert.True(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa o connect utilizando o certificado.
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

    /// <summary>
    /// Testa o connect por certificado passando o entity name inválido
    /// </summary>
    [Test]
    [ExpectedException(typeof(ACSLoginFailureException))]
    public void ConnectByCertificate_InvalidEntityName() {
      Openbus openbus = Openbus.GetInstance();
      String xmlPrivateKey = Crypto.ReadPrivateKey(testKeyFileName);
      Assert.IsNotEmpty(xmlPrivateKey);

      X509Certificate2 acsCertificate =
        Crypto.ReadCertificate(acsCertificateFileName);
      Assert.IsNotNull(acsCertificate);
      IRegistryService registryService = null;
      try {
        registryService = openbus.Connect("null", xmlPrivateKey, acsCertificate);
      }
      finally {
        Assert.Null(registryService);
        Assert.False(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa o connect por certificado passando a cheve privada nula. 
    /// </summary>
    [Test]
    [ExpectedException(typeof(ArgumentException))]
    public void ConnectByCertificate_NullKey() {
      Openbus openbus = Openbus.GetInstance();

      X509Certificate2 acsCertificate =
        Crypto.ReadCertificate(acsCertificateFileName);
      Assert.IsNotNull(acsCertificate);

      IRegistryService registryService = null;
      try {
        registryService = openbus.Connect(entityName, null, acsCertificate);
      }
      finally {
        Assert.Null(registryService);
        Assert.False(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa o connect por certificado passando o certificado digital nulo. 
    /// </summary>
    [Test]
    [ExpectedException(typeof(ArgumentException))]
    public void ConnectByCertificate_NullACSCertificate() {
      Openbus openbus = Openbus.GetInstance();
      String xmlPrivateKey = Crypto.ReadPrivateKey(testKeyFileName);
      Assert.IsNotEmpty(xmlPrivateKey);

      IRegistryService registryService = null;
      try {
        registryService = openbus.Connect(entityName, xmlPrivateKey, null);
      }
      finally {
        Assert.Null(registryService);
        Assert.False(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa conectar duas vezes ao barramento utilizando o método connect 
    /// por certificado
    /// </summary>
    [Test]
    [ExpectedException(typeof(ACSLoginFailureException))]
    public void ConnectByCertificate_Twice() {
      Openbus openbus = Openbus.GetInstance();
      String xmlPrivateKey = Crypto.ReadPrivateKey(testKeyFileName);
      Assert.IsNotEmpty(xmlPrivateKey);

      X509Certificate2 acsCertificate =
        Crypto.ReadCertificate(acsCertificateFileName);
      Assert.IsNotNull(acsCertificate);

      IRegistryService registryService =
        openbus.Connect(entityName, xmlPrivateKey, acsCertificate);
      Assert.NotNull(registryService);

      registryService = null;
      try {
        registryService = openbus.Connect(entityName, xmlPrivateKey, acsCertificate);
      }
      finally {
        Assert.Null(registryService);
        Assert.True(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa o connect utilizando a credencial.
    /// </summary>
    [Test]
    public void ConnectByCredential() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = openbus.Connect(userLogin, userPassword);
      Assert.NotNull(registryService);

      Credential myCredential = openbus.Credential;
      registryService = openbus.Connect(myCredential);
      Assert.NotNull(registryService);
      Assert.True(openbus.Disconnect());
    }

    /// <summary>
    /// Testa o connect por credencial passando a credencial nula.
    /// </summary>
    [Test]
    [ExpectedException(typeof(ArgumentException))]
    public void ConnectByCredential_NullCredencial() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = openbus.Connect(userLogin, userPassword);
      Assert.NotNull(registryService);
      registryService = null;

      Credential myCredencial = new Credential();
      try {
        registryService = openbus.Connect(myCredencial);
      }
      finally {
        Assert.Null(registryService);
        Assert.True(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa o connect por credencial passando a credencial inválida.
    /// </summary>
    [Test]
    [ExpectedException(typeof(InvalidCredentialException))]
    public void ConnectByCredential_InvalidCredencial() {
      Openbus openbus = Openbus.GetInstance();
      IRegistryService registryService = openbus.Connect(userLogin, userPassword);
      Assert.NotNull(registryService);
      registryService = null;

      Credential myCredential = new Credential("null", "null", "");
      try {
        registryService = openbus.Connect(myCredential);
      }
      finally {
        Assert.Null(registryService);
        Assert.True(openbus.Disconnect());
      }
    }

    /// <summary>
    /// Testa o IsConnected
    /// </summary>
    [Test]
    public void IsConnected() {
      Openbus openbus = Openbus.GetInstance();
      Assert.False(openbus.isConnected());
      Assert.NotNull(openbus.Connect(userLogin, userPassword));
      Assert.True(openbus.isConnected());
      Assert.True(openbus.Disconnect());
      Assert.False(openbus.isConnected());
    }

    /// <summary>
    /// Testa se disconectar do barramento.
    /// </summary>
    [Test]
    public void Disconnect() {
      Openbus openbus = Openbus.GetInstance();
      Assert.False(openbus.Disconnect());
      Assert.NotNull(openbus.Connect(userLogin, userPassword));
      Assert.True(openbus.Disconnect());
      Assert.False(openbus.Disconnect());
    }

    /// <summary>
    /// Testa o GetAccessControlService
    /// </summary>
    [Test]
    public void GetAccessControlService() {
      Openbus openbus = Openbus.GetInstance();
      Assert.Null(openbus.GetAccessControlService());
      Assert.NotNull(openbus.Connect(userLogin, userPassword));
      Assert.NotNull(openbus.GetAccessControlService());
      Assert.True(openbus.Disconnect());
      Assert.Null(openbus.GetAccessControlService());
    }

    /// <summary>
    /// Testa o GetRegistryService
    /// </summary>
    [Test]
    public void GetRegistryService() {
      Openbus openbus = Openbus.GetInstance();
      Assert.Null(openbus.GetRegistryService());
      Assert.NotNull(openbus.Connect(userLogin, userPassword));
      Assert.NotNull(openbus.GetRegistryService());
      Assert.True(openbus.Disconnect());
      Assert.Null(openbus.GetRegistryService());
    }

    /// <summary>
    /// Testa o GetSessionService
    /// </summary>
    [Test]
    public void GetSessionService() {
      Openbus openbus = Openbus.GetInstance();
      Assert.Null(openbus.GetSessionService());
      Assert.NotNull(openbus.Connect(userLogin, userPassword));
      Assert.NotNull(openbus.GetSessionService());
      Assert.True(openbus.Disconnect());
      Assert.Null(openbus.GetSessionService());
    }

    #endregion

    #endregion
  }
}
