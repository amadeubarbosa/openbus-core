using System;


namespace Demo_Hello
{
  /// <summary>
  /// Implementação do servant IHello.
  /// </summary>
  class HelloImpl : demoidl.hello.IHello
  {
    #region IHello Members

    public void sayHello() {
      Console.WriteLine("Hello!");
    }

    #endregion
  }
}
