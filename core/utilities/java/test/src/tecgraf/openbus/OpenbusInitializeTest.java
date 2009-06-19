package tecgraf.openbus;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import java.util.logging.Level;

import org.junit.BeforeClass;
import org.junit.Test;
import org.omg.CORBA.UserException;

import tecgraf.openbus.exception.OpenBusException;
import tecgraf.openbus.util.Log;

public class OpenbusInitializeTest {

  private static Properties props;

  private String hostName;
  private int hostPort;

  /**
   * Construtor
   * 
   * @throws IOException
   */
  public OpenbusInitializeTest() throws IOException {
    // Carregando o arquivo de configura��o
    Properties defaultProps = new Properties();
    InputStream in =
      this.getClass().getResourceAsStream("/AllTests.properties");
    defaultProps.load(in);
    in.close();

    this.hostName = defaultProps.getProperty("hostName");
    this.hostPort = Integer.valueOf(defaultProps.getProperty("hostPort"));
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

    Log.setLogsLevel(Level.WARNING);
  }

  /**
   * Testa o resetAndInitialize passando o Properties null.
   * 
   * @throws OpenBusException
   * @throws UserException
   */
  @Test(expected = IllegalArgumentException.class)
  public void resetAndInitializeNullProps() throws OpenBusException,
    UserException {
    Openbus.getInstance().resetAndInitialize(null, null, hostName, hostPort);
  }

  /**
   * Testa o resetAndInitialize passando ACSHost null.
   * 
   * @throws OpenBusException
   * @throws UserException
   */
  @Test(expected = IllegalArgumentException.class)
  public void resetAndInitializeNullHost() throws OpenBusException,
    UserException {
    Openbus.getInstance().resetAndInitialize(null, props, null, 0);
  }

  /**
   * Testa o resetAndInitialize passando ACSPort null.
   * 
   * @throws OpenBusException
   * @throws UserException
   */
  @Test(expected = IllegalArgumentException.class)
  public void resetAndInitializeInvalidPort() throws OpenBusException,
    UserException {
    Openbus.getInstance().resetAndInitialize(null, props, hostName, -1);
  }

}
