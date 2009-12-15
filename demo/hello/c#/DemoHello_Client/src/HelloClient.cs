using DemoHello_Client.Properties;
using OpenbusAPI;
using OpenbusAPI.Logger;
using openbusidl.rs;
using scs.core;
using System;
using demoidl.hello;

namespace DemoHello_Client
{
  /// <summary>
  /// Cliente do demo hello.
  /// </summary>
  class HelloClient
  {

    private static Openbus openbus;

    static void Main(string[] args) {
      AppDomain.CurrentDomain.ProcessExit += new EventHandler(CurrentDomain_ProcessExit);

      string hostName = DemoConfig.Default.hostName;
      int hostPort = DemoConfig.Default.hostPort;

      Log.setLogsLevel(Level.WARN);

      openbus = Openbus.GetInstance();
      openbus.Init(hostName, hostPort);

      string userLogin = DemoConfig.Default.userLogin;
      string userPassword = DemoConfig.Default.userPassword;

      IRegistryService registryService = openbus.Connect(userLogin, userPassword);

      string[] facets = new string[] { "IHello" };
      ServiceOffer[] offers = registryService.find(facets);

      if (offers.Length < 1) {
        Console.WriteLine("O serviço Hello não se encontra no barramento.");
        Environment.Exit(1);
      }
      if (offers.Length > 1)
        Console.WriteLine("Existe mais de um serviço Hello no barramento.");

      IComponent component = offers[0].member;
      MarshalByRefObject helloObj = component.getFacetByName("IHello");
      if (helloObj == null) {
        Console.WriteLine("Não foi possível encontrar uma faceta com esse nome.");
        Environment.Exit(1);
      }

      IHello hello = helloObj as IHello;
      if (hello == null) {
        Console.WriteLine("Faceta encontrada não implementa IHello.");
        Environment.Exit(1);
      }

      hello.sayHello();

      Console.WriteLine("Fim.");
      Console.ReadLine();
    }

    static void CurrentDomain_ProcessExit(object sender, EventArgs e) {
      openbus.Disconnect();
      openbus.Destroy();
    }
  }

}
