package tecgraf.openbus;

import java.io.IOException;
import java.io.InputStream;
import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.util.Properties;
import java.util.logging.Level;

import openbusidl.acs.Credential;
import openbusidl.acs.IAccessControlService;
import openbusidl.rs.IRegistryService;

import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import org.omg.CORBA.UserException;

import tecgraf.openbus.exception.ACSLoginFailureException;
import tecgraf.openbus.exception.OpenBusException;
import tecgraf.openbus.lease.LeaseExpiredCallback;
import tecgraf.openbus.util.CryptoUtils;
import tecgraf.openbus.util.Log;

public class OpenbusTest {
  private static Properties props;

  private String userLogin;
  private String userPassword;
  private String hostName;
  private int hostPort;

  private String testKey;
  private String acsCertificate;
  private String testCertificateName;

  /**
   * Construtor
   * 
   * @throws IOException
   */
  public OpenbusTest() throws IOException {
    // Carregando o arquivo de configura��o
    Properties props = new Properties();
    InputStream in =
      this.getClass().getResourceAsStream("/AllTests.properties");
    props.load(in);
    in.close();

    this.userLogin = props.getProperty("userLogin");
    this.userPassword = props.getProperty("userPassword");
    this.hostName = props.getProperty("hostName");
    this.hostPort = Integer.valueOf(props.getProperty("hostPort"));

    this.testKey = props.getProperty("testKey");
    this.acsCertificate = props.getProperty("ACServiceCert");
    this.testCertificateName = props.getProperty("testCertificateName");
  }

  /**
   * Este m�todo � chamado antes de todos os testCases.
   */
  @BeforeClass
  public static void beforeClass() {
    props = new Properties();
    props.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    props.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");

    Log.setLogsLevel(Level.FINEST);
  }

  /**
   * Este m�todo � chamado antes de cada testCase.
   * 
   * @throws OpenBusException
   * @throws UserException
   */
  @Before
  public void beforeTest() throws OpenBusException, UserException {
    Openbus openbus = Openbus.getInstance();
    openbus.init(null, props, hostName, hostPort);
  }

  /**
   * Este m�todo � chamado depois de cada testCase.
   * 
   * @throws OpenBusException
   * @throws UserException
   */
  @After
  public void afterTest() throws OpenBusException, UserException {
    Openbus openbus = Openbus.getInstance();
    openbus.destroy();
  }

  /**
   * Testa o connect passando usu�rio e senha v�lido
   * 
   * @throws OpenBusException
   */
  @Test
  public void connectByPassword() throws OpenBusException {
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = openbus.connect(userLogin, userPassword);
    Assert.assertNotNull(registryService);
    Assert.assertTrue(openbus.disconnect());
  }

  /**
   * Testa o connect passando usu�rio e senha nulos.
   * 
   * @throws OpenBusException
   */
  @Test(expected = IllegalArgumentException.class)
  public void connectByPasswordLoginNull() throws OpenBusException {
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = null;
    try {
      registryService = openbus.connect(null, null);
    }
    finally {
      Assert.assertNull(registryService);
      Assert.assertFalse(openbus.disconnect());
    }
  }

  /**
   * Testa o connect passando usu�rio e senha inv�lido.
   * 
   * @throws OpenBusException
   */
  @Test(expected = ACSLoginFailureException.class)
  public void connectByPasswordInvalidLogin() throws OpenBusException {
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = null;
    try {
      registryService = openbus.connect("null", "null");
    }
    finally {
      Assert.assertNull(registryService);
      Assert.assertFalse(openbus.disconnect());
    }
  }

  /**
   * Testa o connect passando o certificado.
   * 
   * @throws OpenBusException
   * @throws Exception
   */
  @Test
  public void connectByCertificate() throws OpenBusException, Exception {
    RSAPrivateKey key = CryptoUtils.readPrivateKey(testKey);
    X509Certificate acsCert = CryptoUtils.readCertificate(acsCertificate);
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService =
      openbus.connect(testCertificateName, key, acsCert);
    Assert.assertNotNull(registryService);
    Assert.assertTrue(openbus.disconnect());
  }

  /**
   * Testa o connect passando a chave nula.
   * 
   * @throws OpenBusException
   * @throws Exception
   */
  @Test(expected = IllegalArgumentException.class)
  public void connectByCertificateNullKey() throws OpenBusException, Exception {
    X509Certificate acsCert = CryptoUtils.readCertificate(acsCertificate);
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = null;
    try {
      registryService = openbus.connect(testCertificateName, null, acsCert);
    }
    finally {
      Assert.assertNull(registryService);
      Assert.assertFalse(openbus.disconnect());
    }
  }

  /**
   * Testa o connect passando o certificado do ACS nulo.
   * 
   * @throws OpenBusException
   * @throws Exception
   */
  @Test(expected = IllegalArgumentException.class)
  public void connectByCertificateNullACSCertificate() throws OpenBusException,
    Exception {
    RSAPrivateKey Key = CryptoUtils.readPrivateKey(testKey);
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = null;
    try {
      registryService = openbus.connect(testCertificateName, Key, null);
    }
    finally {
      Assert.assertNull(registryService);
      Assert.assertFalse(openbus.disconnect());
    }
  }

  /**
   * Testa o connect por credencial. Este teste faz um loginByPassword para
   * criar uma credencial. Depois faz um loginByCredential passando a credencial
   * criada como par�metro.
   * 
   * @throws OpenBusException
   */
  @Test
  public void connectByCredential() throws OpenBusException {
    Openbus openbus = Openbus.getInstance();
    Credential credential = openbus.getCredential();
    Assert.assertNull(credential);
    // Fazendo o Login de um usu�rio para receber uma credencial.
    IRegistryService registryService = openbus.connect(userLogin, userPassword);
    Assert.assertNotNull(registryService);
    credential = openbus.getCredential();
    Assert.assertNotNull(credential);
    registryService = null;
    registryService = openbus.connect(credential);
    Assert.assertNotNull(registryService);
    Assert.assertTrue(openbus.disconnect());
  }

  /**
   * Testa o connect passando uma credencial inv�lida recebida pela classe
   * Openbus.
   * 
   * @throws OpenBusException
   */
  @Test(expected = IllegalArgumentException.class)
  public void connectByCredentialNullCredential() throws OpenBusException {
    Openbus openbus = Openbus.getInstance();
    Credential credential = openbus.getCredential();
    Assert.assertNull(credential);
    IRegistryService registryService = openbus.connect(credential);
    Assert.assertNotNull(registryService);
    Assert.assertTrue(openbus.disconnect());
  }

  /**
   * Testa se o m�todo isConnected est� funcionando corretamente.
   * 
   * @throws OpenBusException
   * @throws ACSLoginFailureException
   */
  @Test
  public void isConnected() throws ACSLoginFailureException, OpenBusException {
    Openbus openbus = Openbus.getInstance();
    Assert.assertFalse(openbus.isConnected());
    IRegistryService registryService = openbus.connect(userLogin, userPassword);
    Assert.assertNotNull(registryService);
    Assert.assertTrue(openbus.isConnected());
    Assert.assertTrue(openbus.disconnect());
    Assert.assertFalse(openbus.isConnected());
  }

  /**
   * Testa se o disconect retorna false caso o usu�rio n�o esteja conectado
   * 
   * @throws OpenBusException
   */
  @Test
  public void disconnected() throws OpenBusException {
    Openbus openbus = Openbus.getInstance();
    Assert.assertFalse(openbus.disconnect());
  }

  /**
   * Testa se o m�todo getORB retorna um objeto
   * 
   * @throws OpenBusException
   */
  @Test
  public void getOrb() throws OpenBusException {
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = openbus.connect(userLogin, userPassword);
    Assert.assertNotNull(registryService);
    Assert.assertNotNull(openbus.getORB());
    Assert.assertTrue(openbus.disconnect());
  }

  /**
   * Testa se o m�todo getRootPOA retorna um objeto
   * 
   * @throws OpenBusException
   * @throws UserException
   */
  @Test
  public void getRootPOA() throws OpenBusException, UserException {
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = openbus.connect(userLogin, userPassword);
    Assert.assertNotNull(registryService);
    Assert.assertNotNull(openbus.getRootPOA());
    Assert.assertTrue(openbus.disconnect());
  }

  /**
   * Testa se o m�todo getAccessControlService retorna um objeto
   * 
   * @throws OpenBusException
   * @throws UserException
   */
  @Test
  public void getAccessControlService() throws OpenBusException, UserException {
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = openbus.connect(userLogin, userPassword);
    Assert.assertNotNull(registryService);
    Assert.assertNotNull(openbus.getAccessControlService());
    Assert.assertTrue(openbus.disconnect());
  }

  /**
   * Testa se o m�todo getRegistryService retorna um objeto
   * 
   * @throws OpenBusException
   * @throws UserException
   */
  @Test
  public void getRegistryService() throws OpenBusException, UserException {
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = openbus.connect(userLogin, userPassword);
    Assert.assertNotNull(registryService);
    Assert.assertNotNull(openbus.getAccessControlService().getRegistryService());
    Assert.assertTrue(openbus.disconnect());
  }

  /**
   * Testa se o m�todo getSessionService retorna um objeto
   * 
   * @throws OpenBusException
   * @throws UserException
   */
  @Test
  public void getSessionService() throws OpenBusException, UserException {
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = openbus.connect(userLogin, userPassword);
    Assert.assertNotNull(registryService);
    Assert.assertNotNull(openbus.getSessionService());
    Assert.assertTrue(openbus.disconnect());
  }

  /**
   * Testa se a callback de expira��o da credencial � corretament acionada.
   *
   * @throws OpenBusException
   */
  @Test(timeout=120*1000)
  public void credentialExpired() throws OpenBusException {
    Openbus openbus = Openbus.getInstance();
    IRegistryService registryService = openbus.connect(userLogin, userPassword);
    Assert.assertNotNull(registryService);
    class LeaseExpiredCallbackImpl implements LeaseExpiredCallback {
      private volatile boolean expired;

      LeaseExpiredCallbackImpl() {
        this.expired = false;
      }

      public void expired() {
        this.expired = true;
      }

      public boolean isExpired() {
        return this.expired;
      }
    }
    LeaseExpiredCallbackImpl callback = new LeaseExpiredCallbackImpl();
    openbus.addLeaseExpiredCallback(callback);
    IAccessControlService acs = openbus.getAccessControlService();
    acs.logout(openbus.getCredential());
    while (!callback.isExpired()) {
     ;
    }
  }
}
