package tecgraf.openbus.demo.eventSink;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.security.GeneralSecurityException;
import java.util.Properties;
import java.util.logging.Level;

import openbusidl.rs.IRegistryService;
import openbusidl.ss.ISession;
import openbusidl.ss.ISessionHelper;
import openbusidl.ss.ISessionService;
import openbusidl.ss.SessionEvent;
import openbusidl.ss.SessionEventSink;
import openbusidl.ss.SessionEventSinkHelper;

import org.omg.CORBA.Any;
import org.omg.CORBA.ORB;
import org.omg.CORBA.StringHolder;
import org.omg.CORBA.UserException;

import scs.core.ComponentId;
import scs.core.IComponent;
import scs.core.IComponentHelper;
import scs.core.IComponentHolder;
import scs.core.servant.ComponentBuilder;
import scs.core.servant.ComponentContext;
import scs.core.servant.ExtendedFacetDescription;
import tecgraf.openbus.Openbus;
import tecgraf.openbus.exception.OpenBusException;
import tecgraf.openbus.exception.RSUnavailableException;
import tecgraf.openbus.util.Log;

/**
 * Demo que exercita callbacks de Sessão.
 * 
 */
public class EventSinkDemo {
  /**
   * @param args
   * @throws IOException
   * @throws UserException
   * @throws GeneralSecurityException
   * @throws SecurityException
   * @throws InstantiationException
   * @throws IllegalAccessException
   * @throws ClassNotFoundException
   * @throws InvocationTargetException
   * @throws NoSuchMethodException
   * @throws OpenBusException
   */
  public static void main(String[] args) throws IOException, UserException,
    GeneralSecurityException, SecurityException, InstantiationException,
    IllegalAccessException, ClassNotFoundException, InvocationTargetException,
    NoSuchMethodException, OpenBusException {
    Properties props = new Properties();
    InputStream in =
      EventSinkDemo.class.getResourceAsStream("/EventSink.properties");
    try {
      props.load(in);
    }
    finally {
      in.close();
    }

    String host = props.getProperty("host.name");
    String portString = props.getProperty("host.port");
    int port = Integer.valueOf(portString);

    Log.setLogsLevel(Level.WARNING);
    Properties orbProps = new Properties();
    orbProps.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    orbProps.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");
    Openbus bus = Openbus.getInstance();
    bus.resetAndInitialize(args, orbProps, host, port);

    String userLogin = props.getProperty("login");
    String userPassword = props.getProperty("password");

    IRegistryService registryService = bus.connect(userLogin, userPassword);
    if (registryService == null) {
      throw new RSUnavailableException();
    }

    // Cria o componente.
    ORB orb = bus.getORB();
    ComponentBuilder builder = new ComponentBuilder(bus.getRootPOA(), orb);
    ExtendedFacetDescription[] descriptions = new ExtendedFacetDescription[1];
    descriptions[0] =
      new ExtendedFacetDescription("SessionEventSink", SessionEventSinkHelper
        .id(), EventSinkImpl.class.getCanonicalName());
    ComponentId id =
      new ComponentId("EventSink", (byte) 1, (byte) 0, (byte) 0, "Java");
    ComponentContext context = builder.newComponent(descriptions, null, id);

    // cria sessão
    ISessionService sessionService = bus.getSessionService();
    IComponentHolder icholder = new IComponentHolder();
    StringHolder sholder = new StringHolder();
    sessionService.createSession(IComponentHelper.narrow(context
      .getIComponent()), icholder, sholder);
    // cria e adiciona novo membro
    ComponentContext context2 = builder.newComponent(descriptions, null, id);
    IComponent ic2 = IComponentHelper.narrow(context2.getIComponent());
    IComponent sessionIC = icholder.value;
    ISession session =
      ISessionHelper.narrow(sessionIC
        .getFacet("IDL:openbusidl/ss/ISession:1.0"));
    String identifier = session.addMember(ic2);
    // manda eventos push e disconnect
    SessionEventSink sessionES =
      SessionEventSinkHelper.narrow(sessionIC
        .getFacet("IDL:openbusidl/ss/SessionEventSink:1.0"));
    Any any = orb.create_any();
    any.insert_string("evento de teste");
    sessionES.push(new SessionEvent("teste", any));
    sessionES.disconnect();
    // remove membros
    session.removeMember(identifier);
    session.removeMember(sholder.value);
    // desconecta
    bus.disconnect();
    System.out.println("Finalizando...");
  }
}
