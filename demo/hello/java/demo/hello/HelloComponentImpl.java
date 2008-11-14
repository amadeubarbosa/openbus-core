package demo.hello;

import java.util.ArrayList;

import org.omg.CORBA.Object;
import org.omg.CORBA.UserException;
import org.omg.PortableServer.POA;

import scs.core.ComponentId;
import scs.core.FacetDescription;
import scs.core.servant.IComponentServant;

public class HelloComponentImpl extends IComponentServant {
  private POA poa;
  private Object helloObject;

  public HelloComponentImpl(POA poa) throws UserException {
    this.poa = poa;
    HelloImpl helloImpl = new HelloImpl();
    helloObject = this.poa.servant_to_reference(helloImpl);
  }

  @Override
  protected ComponentId createComponentId() {
    return new ComponentId("HelloComponent", 1);
  }

  @Override
  protected ArrayList<FacetDescription> createFacets() {
    FacetDescription facetDescription =
      new FacetDescription("hello", "IDL:demoidl/hello/IHello:1.0", helloObject);
    ArrayList<FacetDescription> facetDescriptions =
      new ArrayList<FacetDescription>();
    facetDescriptions.add(facetDescription);
    return facetDescriptions;
  }

  @Override
  protected boolean doShutdown() {
    return true;
  }

  @Override
  protected boolean doStartup() {
    return true;
  }
}
