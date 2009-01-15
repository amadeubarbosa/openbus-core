package demo.hello;

import scs.core.servant.ComponentContext;
import demoidl.hello.IHelloPOA;

public final class HelloImpl extends IHelloPOA {
  private ComponentContext context;

  public HelloImpl(ComponentContext context) {
    this.context = context;
  }

  @Override
  public org.omg.CORBA.Object _get_component() {
    return context.getIComponent();
  }

  @Override
  public void sayHello() {
    System.out.println("Hello !!!");
  }
}
