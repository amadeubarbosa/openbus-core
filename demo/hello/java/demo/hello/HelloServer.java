package demo.hello;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.util.Properties;

import openbus.AccessControlServiceWrapper;
import openbus.ORBWrapper;
import openbus.Registry;
import openbus.RegistryServiceWrapper;
import openbus.common.CryptoUtils;
import openbus.common.exception.OpenBusException;
import openbusidl.rs.Property;
import openbusidl.rs.ServiceOffer;

import org.omg.CORBA.UserException;
import org.omg.PortableServer.POA;

import scs.core.IComponent;
import scs.core.IComponentHelper;

public class HelloServer {
  public static void main(String[] args) throws OpenBusException,
    GeneralSecurityException, IOException, UserException {
    RSAPrivateKey privateKey = CryptoUtils.readPrivateKey("HelloService.key");
    X509Certificate acsCertificate = CryptoUtils
      .readCertificate("AccessControlService.crt");

    Properties props = new Properties();
    props.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    props.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");
    ORBWrapper orb = new ORBWrapper(props);
    Registry.getInstance().setORBWrapper(orb);

    AccessControlServiceWrapper acs = new AccessControlServiceWrapper(orb,
      "localhost", 2089);
    Registry.getInstance().setACS(acs);

    assert (acs.loginByCertificate("HelloService", privateKey, acsCertificate));

    POA rootPOA = orb.getRootPOA();
    HelloComponentImpl helloComponentImpl = new HelloComponentImpl(rootPOA);
    org.omg.CORBA.Object obj = rootPOA.servant_to_reference(helloComponentImpl);
    IComponent component = IComponentHelper.narrow(obj);
    component.startup();
    ServiceOffer serviceOffer = new ServiceOffer(new Property[0], component);

    RegistryServiceWrapper registryService = acs.getRegistryService();
    assert (registryService != null);
    registryService.register(serviceOffer);

    orb.run();

    assert (acs.logout());
    System.out.println("Finalizando...");
  }
}
