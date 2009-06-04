package demo.hello;

import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.util.Properties;

import openbus.Registry;
import openbus.common.CryptoUtils;
import openbusidl.rs.IRegistryService;
import openbusidl.rs.Property;
import openbusidl.rs.ServiceOffer;

import org.omg.CORBA.ORB;
import org.omg.CORBA.StringHolder;

import scs.core.ComponentId;
import scs.core.IComponent;
import scs.core.IComponentHelper;
import scs.core.servant.ComponentBuilder;
import scs.core.servant.ComponentContext;
import scs.core.servant.ExtendedFacetDescription;
import scs.core.servant.IComponentServant;
import scs.core.servant.IMetaInterfaceServant;

public class HelloServer {
  public static void main(String[] args) throws Exception {
    // Obtencão da chave privada deste servidor.
    RSAPrivateKey privateKey = CryptoUtils.readPrivateKey("HelloService.key");

    // Obtencão do certificado do Servico de Controle de Acesso.
    X509Certificate acsCertificate =
      CryptoUtils.readCertificate("AccessControlService.crt");

    Properties props = new Properties();
    props.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    props.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");

    Registry bus = Registry.getInstance();
    bus.resetAndInitialize(args, props, "localhost", 2089);
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

    // Acessa o OpenBus
    IRegistryService registryService =
      bus.connect("HelloService", privateKey, acsCertificate);
    assert (registryService != null);

    org.omg.CORBA.Object obj = context.getIComponent();
    IComponent component = IComponentHelper.narrow(obj);
    ServiceOffer serviceOffer = new ServiceOffer(new Property[0], component);
    StringHolder registrationId = new StringHolder();
    registryService.register(serviceOffer, registrationId);

    orb.run();
  }
}
