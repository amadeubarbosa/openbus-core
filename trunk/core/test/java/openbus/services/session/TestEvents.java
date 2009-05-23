/*
 * $Id$
 */
package openbus.services.session;

import java.util.Properties;

import openbus.common.ClientConnectionManager;
import openbus.common.CredentialManager;
import openbus.common.Utils;
import openbusidl.acs.IAccessControlService;
import openbusidl.rs.IRegistryService;
import openbusidl.ss.ISession;
import openbusidl.ss.ISessionHolder;
import openbusidl.ss.ISessionService;
import openbusidl.ss.SessionEvent;

import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.omg.CORBA.Any;
import org.omg.CORBA.ORB;
import org.omg.CORBA.StringHolder;
import org.omg.CORBA.ORBPackage.InvalidName;
import org.omg.PortableServer.POA;
import org.omg.PortableServer.POAManagerPackage.AdapterInactive;
import org.omg.PortableServer.POAPackage.ServantNotActive;
import org.omg.PortableServer.POAPackage.WrongPolicy;

import scs.core.IComponent;
import scs.core.IComponentHelper;
import scs.core.StartupFailed;

/**
 * Teste do Serviço de Eventos.
 * 
 * @author Tecgraf/PUC-Rio
 */
public class TestEvents {
  /**
   * O ORB.
   */
  private ORB orb;
  /**
   * O RootPOA.
   */
  private POA rootPoa;
  /**
   * Representa a conexão com o barramento.
   */
  private ClientConnectionManager connection;

  /**
   * Inicia o ORB e conecta-se ao barramento.
   * 
   * @throws InvalidName
   * @throws AdapterInactive
   */
  @Before
  public void connect() throws InvalidName, AdapterInactive {
    Properties props = new Properties();
    props.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    props.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");
    props.put("org.omg.PortableInterceptor.ORBInitializerClass.ClientInit",
      "openbus.common.interceptors.ClientInitializer");

    this.orb = ORB.init((String[]) null, props);
    this.rootPoa = Utils.getRootPoa(this.orb);

    this.connection =
      new ClientConnectionManager(this.orb, "localhost", 2089, "tester",
        "tester");
    this.connection.connect();
  }

  /**
   * Executa os testes do Serviço de Sessão.
   * 
   * @throws WrongPolicy
   * @throws StartupFailed
   * @throws ServantNotActive
   */
  @Test
  public void sessionService() throws WrongPolicy, StartupFailed,
    ServantNotActive {
    Assert.assertTrue(this.connection.isConnected());
    ISessionService sessionService = this.getSessionService();
    Assert.assertNull(sessionService.getSession());
    ISessionHolder sessionHolder = new ISessionHolder();
    SessionMember member1 = new SessionMember(this.rootPoa);
    IComponent component1 =
      IComponentHelper.narrow(this.rootPoa.servant_to_reference(member1));
    component1.startup();
    sessionService.createSession(component1, sessionHolder, new StringHolder());

    ISession session = sessionService.getSession();
    Assert.assertEquals(sessionHolder.value.getIdentifier(), session
      .getIdentifier());
    SessionMember member2 = new SessionMember(this.rootPoa);
    IComponent component2 =
      IComponentHelper.narrow(this.rootPoa.servant_to_reference(member2));
    component2.startup();
    session.addMember(component2);

    Any dataChannelAny = this.orb.create_any();

    /*
     * DataChannel dataChannel = new DataChannel("localhost", (short) 2049, new
     * byte[0], new byte[0], true, 1024L);
     * DataChannelHelper.insert(dataChannelAny, dataChannel);
     */
    dataChannelAny.insert_long(100);

    SessionEvent ev =
      new SessionEvent("IDL:openbusidl/ps/DataChannel:1.0", dataChannelAny);
    session.push(ev);
    session.disconnect();
  }

  /**
   * Obtém o Serviço de Sessão.
   * 
   * @return O Serviço de Sessão.
   */
  private ISessionService getSessionService() {
    IAccessControlService acs = CredentialManager.getInstance().getACS();
    Assert.assertNotNull(acs);
    IRegistryService registryService = acs.getRegistryService();
    Assert.assertNotNull(registryService);
    ISessionService sessionService = Utils.getSessionService(registryService);
    Assert.assertNotNull(sessionService);
    return sessionService;
  }

  /**
   * Desconecta do barramento.
   */
  @After
  public void disconnect() {
    this.connection.disconnect();
  }
}