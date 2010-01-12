using OpenbusAPI.Logger;
using OpenbusAPI;
using OpenbusAPI.Security;
using System.Security.Cryptography.X509Certificates;
using openbusidl.rs;
using DemoDelegate_Server.Properties;
using System.Security.Cryptography;


namespace DemoDelegate_Server
{
  /// <summary>
  /// Servidor do demo delegate.
  /// </summary>
  class HelloServer
  {

    static void Main(string[] args) {

      string hostName = DemoConfig.Default.hostName;
      int hostPort = DemoConfig.Default.hostPort;

      Log.setLogsLevel(Level.WARN);

      Openbus openbus = Openbus.GetInstance();
      openbus.Init(hostName, hostPort);

      string entityName = DemoConfig.Default.entityName;
      string privaKeyFile = DemoConfig.Default.xmlPrivateKey;
      string acsCertificateFile = DemoConfig.Default.acsCertificateFileName;

      RSACryptoServiceProvider privateKey = Crypto.ReadPrivateKey(privaKeyFile);
      X509Certificate2 acsCertificate =
        Crypto.ReadCertificate(acsCertificateFile);

      /* TODO: Cria o componente */

      IRegistryService registryService =
        openbus.Connect(entityName, privateKey, acsCertificate);

      /* TODO: Registra o componente no RegistryService */

      openbus.Run();
    }

  }
}
