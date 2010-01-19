using DemoDelegate_Client.Properties;
using OpenbusAPI;
using OpenbusAPI.Logger;
using openbusidl.rs;
using scs.core;
using System;
using demoidl.demoDelegate;
using System.Threading;
using openbusidl.acs;
using OpenbusAPI.Security;
using System.Security.Cryptography.X509Certificates;
using System.Security.Cryptography;

namespace DemoDelegate_Client
{
  /// <summary>
  /// Cliente do demo delegate.
  /// </summary>
  class HelloClient
  {
    private static Openbus openbus;

    static void Main(string[] args) {
      AppDomain.CurrentDomain.ProcessExit += CurrentDomain_ProcessExit;

      string hostName = DemoConfig.Default.hostName;
      int hostPort = DemoConfig.Default.hostPort;

      Log.setLogsLevel(Level.WARN);

      openbus = Openbus.GetInstance();
      openbus.Init(hostName, hostPort);

      string userLogin = DemoConfig.Default.login;
      string userPassword = DemoConfig.Default.password;
      string entityName = DemoConfig.Default.entityName;

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

      Thread a = new Thread(DoWork);
      Thread b = new Thread(DoWork);
      a.Start(new DoWorkData("A", hello));
      b.Start(new DoWorkData("B", hello));

      a.Join();
      b.Join();

      Console.WriteLine("Fim");
      Console.ReadLine();
    }

    static void DoWork(Object state) {
      DoWorkData data = (DoWorkData)state;

      String name = data.Name;
      IHello hello = data.IHelloFacet;
      if (String.IsNullOrEmpty(name) || hello == null) {
        Console.WriteLine("Erro! Parâmetro state não é do tipo DoWorkData");
        Environment.Exit(1);
      }

      Credential credential = openbus.Credential;
      credential._delegate = name;
      openbus.setThreadCredential(credential);

      for (int i = 0; i < 10; i++) {
        hello.sayHello(name);
        Thread.Sleep(1000);
      }
    }

    /// <summary>
    /// Evento responsável por fechar a aplicação.
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    static void CurrentDomain_ProcessExit(object sender, EventArgs e) {
      openbus.Disconnect();
      openbus.Destroy();
    }
  }

  /// <summary>
  /// Estrutura de dados responsável por armazenar os parâmetros necessários
  /// para a Thread DoWork.
  /// </summary>
  struct DoWorkData
  {
    public DoWorkData(String name, IHello helloFacet) {
      _name = name;
      _helloFacet = helloFacet;
    }

    public String Name {
      get { return _name; }
    }
    private String _name;

    public IHello IHelloFacet {
      get { return _helloFacet; }
    }
    private IHello _helloFacet;
  }
}
