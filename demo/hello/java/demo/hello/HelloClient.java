package demo.hello;

import java.util.Properties;

import openbus.AccessControlServiceWrapper;
import openbus.ORBWrapper;
import openbus.Registry;
import openbus.RegistryServiceWrapper;
import openbus.common.exception.OpenBusException;
import openbusidl.rs.Property;
import openbusidl.rs.ServiceOffer;

import org.omg.CORBA.Object;

import scs.core.IComponent;
import demoidl.hello.IHello;
import demoidl.hello.IHelloHelper;

public class HelloClient {
  public static void main(String[] args) throws OpenBusException {
    String userLogin = "tester";
    String userPassword = "tester";

    Properties props = new Properties();
    props.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    props.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");
    ORBWrapper orb = new ORBWrapper(args, props);
    Registry.getInstance().setORBWrapper(orb);

    AccessControlServiceWrapper acs =
      new AccessControlServiceWrapper(orb, "localhost", 2089);
    Registry.getInstance().setACS(acs);

    assert (acs.loginByPassword(userLogin, userPassword));

    RegistryServiceWrapper registryService = acs.getRegistryService();
    assert (registryService != null);

    Property property = new Property("facets", new String[] { "Hello" });
    ServiceOffer[] servicesOffers =
      registryService.find(new Property[] { property });
    assert (servicesOffers.length == 1);
    ServiceOffer serviceOffer = servicesOffers[0];
    IComponent component = serviceOffer.member;

    Object helloObject = component.getFacetByName("Hello");
    IHello hello = IHelloHelper.narrow(helloObject);
    hello.sayHello();

    assert (acs.logout());
    System.out.println("Finalizando...");
  }
}
