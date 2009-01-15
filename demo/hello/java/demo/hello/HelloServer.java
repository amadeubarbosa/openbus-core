package demo.hello;

import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.util.Properties;

import openbus.AccessControlServiceWrapper;
import openbus.ORBWrapper;
import openbus.Registry;
import openbus.RegistryServiceWrapper;
import openbus.common.CryptoUtils;
import openbusidl.rs.Property;
import openbusidl.rs.ServiceOffer;

import org.omg.PortableServer.POA;

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

    // Cria o ORB.
    Properties props = new Properties();
    props.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    props.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");
    ORBWrapper orb = new ORBWrapper(props);
    Registry.getInstance().setORBWrapper(orb);

    POA rootPOA = orb.getRootPOA();
    Registry.getInstance().setPOA(rootPOA);

    // Cria o componente.
    ComponentBuilder builder = new ComponentBuilder(rootPOA, orb.getORB());
    ExtendedFacetDescription[] descriptions = new ExtendedFacetDescription[3];
    descriptions[0] =
      new ExtendedFacetDescription("IComponent", "IDL:scs/core/IComponent:1.0",
        IComponentServant.class.getCanonicalName());
    descriptions[1] =
      new ExtendedFacetDescription("Hello", "IDL:demoidl/hello/IHello:1.0",
        HelloImpl.class.getCanonicalName());
    descriptions[2] =
      new ExtendedFacetDescription("IMetaInterface",
        "IDL:scs/core/IMetaInterface:1.0", IMetaInterfaceServant.class
          .getCanonicalName());
    ComponentContext context =
      builder.newComponent(descriptions, null, new ComponentId("Hello",
        (byte) 1, (byte) 0, (byte) 0, "Java"));

    // Acessa o OpenBus
    AccessControlServiceWrapper acs =
      new AccessControlServiceWrapper(orb, "localhost", 2089);
    Registry.getInstance().setACS(acs);

    assert (acs.loginByCertificate("HelloService", privateKey, acsCertificate));

    RegistryServiceWrapper registryService = acs.getRegistryService();
    assert (registryService != null);

    org.omg.CORBA.Object obj = context.getIComponent();
    IComponent component = IComponentHelper.narrow(obj);
    ServiceOffer serviceOffer = new ServiceOffer(new Property[0], component);
    registryService.register(serviceOffer);

    orb.run();

    assert (acs.logout());
    System.out.println("Finalizando...");
  }
}
