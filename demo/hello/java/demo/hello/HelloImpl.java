package demo.hello;

import demoidl.hello.IHelloPOA;

public final class HelloImpl extends IHelloPOA {
  @Override
  public void sayHello() {
    System.out.println("Hello !!!");
  }
}
