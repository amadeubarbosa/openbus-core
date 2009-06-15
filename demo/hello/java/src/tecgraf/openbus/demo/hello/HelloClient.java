package tecgraf.openbus.demo.hello;

import java.util.Properties;

import openbusidl.rs.IRegistryService;
import openbusidl.rs.Property;
import openbusidl.rs.ServiceOffer;

import org.omg.CORBA.Object;

import scs.core.IComponent;
import tecgraf.openbus.Openbus;
import tecgraf.openbus.exception.OpenBusException;
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
    Openbus bus = Openbus.getInstance();
    bus.resetAndInitialize(args, props, "localhost", 2089);

    IRegistryService registryService = bus.connect(userLogin, userPassword);
    assert (registryService != null);

    Property property = new Property("facets", new String[] { "IHello" });
    ServiceOffer[] servicesOffers =
      registryService.find(new Property[] { property });
    assert (servicesOffers.length == 1);
    ServiceOffer serviceOffer = servicesOffers[0];
    IComponent component = serviceOffer.member;

    Object helloObject = component.getFacetByName("IHello");
    IHello hello = IHelloHelper.narrow(helloObject);
    hello.sayHello();

    bus.disconnect();
    System.out.println("Finalizando...");
  }
}
