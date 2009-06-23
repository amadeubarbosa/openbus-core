package tecgraf.openbus.demo.hello;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.security.GeneralSecurityException;
import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.util.Properties;

import openbusidl.rs.IRegistryService;
import openbusidl.rs.Property;
import openbusidl.rs.ServiceOffer;

import org.omg.CORBA.ORB;
import org.omg.CORBA.StringHolder;
import org.omg.CORBA.UserException;

import scs.core.ComponentId;
import scs.core.IComponent;
import scs.core.IComponentHelper;
import scs.core.servant.ComponentBuilder;
import scs.core.servant.ComponentContext;
import scs.core.servant.ExtendedFacetDescription;
import scs.core.servant.IComponentServant;
import scs.core.servant.IMetaInterfaceServant;
import tecgraf.openbus.Openbus;
import tecgraf.openbus.exception.OpenBusException;
import tecgraf.openbus.exception.RSUnavailableException;
import tecgraf.openbus.util.CryptoUtils;

public class HelloServer {
  public static void main(String[] args) throws IOException, UserException,
    GeneralSecurityException, SecurityException, InstantiationException,
    IllegalAccessException, ClassNotFoundException, InvocationTargetException,
    NoSuchMethodException, OpenBusException {
    Properties props = new Properties();
    InputStream in = HelloClient.class.getResourceAsStream("/Hello.properties");
    try {
      props.load(in);
    }
    finally {
      in.close();
    }

    String host = props.getProperty("host.name");
    String portString = props.getProperty("host.port");
    int port = Integer.valueOf(portString);

    Properties orbProps = new Properties();
    orbProps.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    orbProps.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");
    Openbus bus = Openbus.getInstance();
    bus.resetAndInitialize(args, orbProps, host, port);

    String entityName = props.getProperty("entity.name");
    String privateKeyFile = props.getProperty("private.key");
    String acsCertificateFile = props.getProperty("acs.certificate");

    RSAPrivateKey privateKey = CryptoUtils.readPrivateKey(privateKeyFile);
    X509Certificate acsCertificate =
      CryptoUtils.readCertificate(acsCertificateFile);

    ORB orb = bus.getORB();

    // Cria o componente.
    ComponentBuilder builder = new ComponentBuilder(bus.getRootPOA(), orb);
    ExtendedFacetDescription[] descriptions = new ExtendedFacetDescription[3];
    descriptions[0] =
      new ExtendedFacetDescription("IComponent", "IDL:scs/core/IComponent:1.0",
        IComponentServant.class.getCanonicalName());
    descriptions[1] =
      new ExtendedFacetDescription("IHello", "IDL:demoidl/hello/IHello:1.0",
        HelloImpl.class.getCanonicalName());
    descriptions[2] =
      new ExtendedFacetDescription("IMetaInterface",
        "IDL:scs/core/IMetaInterface:1.0", IMetaInterfaceServant.class
          .getCanonicalName());
    ComponentContext context =
      builder.newComponent(descriptions, null, new ComponentId("Hello",
        (byte) 1, (byte) 0, (byte) 0, "Java"));

    IRegistryService registryService =
      bus.connect(entityName, privateKey, acsCertificate);
    if (registryService == null) {
      throw new RSUnavailableException();
    }

    org.omg.CORBA.Object obj = context.getIComponent();
    IComponent component = IComponentHelper.narrow(obj);
    ServiceOffer serviceOffer = new ServiceOffer(new Property[0], component);
    StringHolder registrationId = new StringHolder();
    registryService.register(serviceOffer, registrationId);

    Runtime.getRuntime().addShutdownHook(new ShutdownThread());

    orb.run();
  }

  private static class ShutdownThread extends Thread {
    @Override
    public void run() {
      Openbus bus = Openbus.getInstance();
      bus.disconnect();
      bus.getORB().shutdown(true);
      bus.getORB().destroy();
    }
  }
}
