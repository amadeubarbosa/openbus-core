using System;
using System.Collections.Generic;
using System.Text;
using Ch.Elca.Iiop;
using OpenbusAPI.Interceptors;

using openbusidl.rs;
using openbusidl.acs;
using System.Runtime.Remoting;
using OpenbusAPI.Lease;
using scs.core;
using System.Threading;
using Ch.Elca.Iiop.Idl;
using openbusidl.ss;
using omg.org.CORBA;
using OpenbusAPI.Exception;
using System.Security.Cryptography.X509Certificates;
using System.Security.Cryptography;
using OpenbusAPI.Security;
using System.Runtime.Remoting.Channels;
using OpenbusAPI.Logger;



namespace OpenbusAPI
{
  /// <summary>
  /// API de acesso a um barramento OpenBus.
  /// </summary>
  public class Openbus
  {
    #region Fields

    /// <summary>
    /// O endereço do serviço de controle de acesso.
    /// </summary>
    private String host;
    /// <summary>
    /// Porta do serviço de controle de acesso.
    /// </summary>
    private int port;
    /// <summary>
    /// O Orb do IIOP.NET.
    /// <!-- Atenção: O orb é singleton, com isso só podemos registrar 
    /// interceptadores uma única vez. -->
    /// </summary>
    OrbServices orb;
    /// <summary>
    /// A faceta IAccessControlService do serviço de controle de acesso.
    /// </summary>
    private IAccessControlService acs;
    /// <summary>
    /// A faceta IComponent do serviço de controle de acesso.
    /// </summary>
    private IComponent acsComponent;
    /// <summary>
    /// A faceta ILeaseProvider do serviço de controle de acesso.
    /// </summary>
    private ILeaseProvider leaseProvider;

    /// <summary>
    /// O renovador de lease.
    /// </summary>
    private LeaseRenewer leaseRenewer;

    /// <summary>
    /// O canal IIOP responsável pela troca de mensagens com o barramento.
    /// </summary>
    private IiopClientChannel channel;

    /// <summary>
    /// Credencial recebida ao se conectar ao barramento.
    /// </summary>
    public Credential Credential {
      get { return credential; }
      set { credential = value; }
    }
    private Credential credential;

    /// <summary>
    /// O slot da credencial da requisição.
    /// </summary>
    public int RequestCredentialSlot {
      set { requestCredentialSlot = value; }
    }
    private int requestCredentialSlot;

    /// <summary>
    /// A faceta IRegistryService do serviço de registro.
    /// </summary>
    private IRegistryService registryService;
    /// <summary>
    /// A faceta ISessionService do serviço de sessão
    /// </summary>
    private ISessionService sessionService;

    #endregion

    #region Consts

    private static readonly String ACCESS_CONTROL_SERVICE_KEY = "ACS";
    private static readonly String LEASE_PROVIDER_KEY = "LP";
    /// <summary>
    /// Chave CORBALOC responsável pela faceta IComponent do serviço de controle de acesso.
    /// </summary>
    private static readonly String ICOMPONENT_KEY = "IC";

    #endregion

    #region Constructors

    /// <summary>
    /// Construtor privado da classe Openbus
    /// </summary>
    private static Openbus instance;
    private Openbus() {
      ResetInstance();
    }

    /// <summary>
    /// Recebe a instância do barramento.
    /// A classe Openbus é um singleton.
    /// </summary>
    /// <returns>O barramento</returns>
    public static Openbus GetInstance() {
      if (instance == null)
        instance = new Openbus();
      return instance;
    }

    #endregion

    #region Internal Members

    /// <summary>
    /// Reinicia o estado do barramento.
    /// </summary>
    private void Reset() {
      this.acs = null;
      this.acsComponent = null;

      this.leaseProvider = null;
      this.leaseRenewer = null;

      this.credential = new Credential();


      this.requestCredentialSlot = -1;

      this.registryService = null;
      this.sessionService = null;
    }

    /// <summary>
    /// Retorna ao seu estado inicial, ou seja, desfaz as definições de atributos realizadas.
    /// </summary>
    private void ResetInstance() {
      this.channel = null;
      this.host = String.Empty;
      this.port = -1;
      Reset();
    }

    /// <summary>
    /// Se conecta ao AccessControlServer por meio do endereço e da porta.
    /// </summary>
    private void FetchACS() {
      this.acs = RemotingServices.Connect(typeof(IAccessControlService),
          "corbaloc::1.0@" + host + ":" + port + "/" + ACCESS_CONTROL_SERVICE_KEY) as IAccessControlService;
      if (this.acs == null) {
        Log.COMMON.Error("O serviço de controle de acesso não foi encontrado");
        throw new ACSUnavailableException();
      }

      this.leaseProvider = RemotingServices.Connect(typeof(ILeaseProvider),
          "corbaloc::1.0@" + host + ":" + port + "/" + LEASE_PROVIDER_KEY) as ILeaseProvider;
      if (this.leaseProvider == null) {
        Log.COMMON.Error("O serviço de controle de acesso não foi encontrado");
        throw new ACSUnavailableException();
      }

      this.acsComponent = RemotingServices.Connect(typeof(IComponent),
          "corbaloc::1.0@" + host + ":" + port + "/" + ICOMPONENT_KEY) as IComponent;
      if (this.acsComponent == null) {
        Log.COMMON.Error("O serviço de controle de acesso não foi encontrado");
        throw new ACSUnavailableException();
      }
    }

    #endregion

    #region OpenbusAPI Implemented

    /// <summary>
    /// Retorna o barramento para o seu estado inicial, ou seja, desfaz as
    /// definições de atributos realizadas. Em seguida, inicializa o Orb.
    /// </summary>
    /// <param name="host">O endereço do serviço de controle de acesso.</param>
    /// <param name="port">A porta do serviço de controle de acesso.</param>
    public void Init(String host, int port) {
      if (this.host != String.Empty)
        throw new OpenbusAlreadyInitialized();

      if ((host == null) || (host == ""))
        throw new ArgumentException("O campo 'host' não é válido");
      if (port < 0)
        throw new ArgumentException("O campo 'port' não pode ser negativo.");

      this.host = host;
      this.port = port;

      //Adicionando os interceptadores
      if (this.orb == null) {
        this.orb = OrbServices.GetSingleton();
        this.orb.RegisterPortableInterceptorInitalizer(new ClientInitializer());
        //TODO Adicionar interceptador servidor.
        this.orb.CompleteInterceptorRegistration();
      }

      //Registrando um canal
      this.channel = new IiopClientChannel();
      ChannelServices.RegisterChannel(channel, false);
    }

    /// <summary>
    /// Coloca o Openbus em modo de espera para receber requisições.
    /// </summary>
    public void Run() {
      Thread.Sleep(Timeout.Infinite);
    }

    /// <summary>
    /// Fornece o serviço de controle de acesso.
    /// </summary>
    /// <returns>A faceta IAccessControlService do serviço de controle 
    /// de acesso.</returns>
    public IAccessControlService GetAccessControlService() {
      return this.acs;
    }

    /// <summary>
    /// Fornece o serviço de registro.
    /// </summary>
    /// <returns>A faceta IRegistryService do serviço de registro.</returns>
    public IRegistryService GetRegistryService() {
      if (this.registryService != null)
        return this.registryService;

      if (this.acsComponent == null) {
        Log.COMMON.Fatal("O IComponent do AccessControlService não está disponível.");
        return null;
      }

      String receptaclesID = Repository.GetRepositoryID(typeof(IReceptacles));
      MarshalByRefObject rgsObjRef = this.acsComponent.getFacet(receptaclesID);
      if (rgsObjRef == null) {
        Log.COMMON.Fatal("O Receptáculo " + receptaclesID + " está nulo.");
        return null;
      }

      IReceptacles receptacles = rgsObjRef as IReceptacles;
      ConnectionDescription[] connections = null;
      try {
        connections = receptacles.getConnections("RegistryServiceReceptacle");
      }
      catch (InvalidName e) {
        Log.COMMON.Error("Erro ao obter o RegistryServiceReceptacle.", e);
      }
      if (connections == null) {
        Log.COMMON.Fatal("Não existem conexões no receptáculo.");
        return null;
      }
      if (connections.Length != 1)
        Log.COMMON.Warn("Existe mais de um RegistryService conectado.");

      MarshalByRefObject objref = connections[0].objref;
      this.registryService = objref as IRegistryService;
      return this.registryService;
    }

    /// <summary>
    /// Fornece o serviço de sessão
    /// </summary>
    /// <returns>A faceta ISessionService do serviço de sessão</returns>
    public ISessionService GetSessionService() {
      if (this.sessionService != null)
        return this.sessionService;

      IRegistryService registryService = this.GetRegistryService();
      if (registryService == null) {
        Log.COMMON.Fatal("Não foi possível acessar o RegistryService");
        return null;
      }
      String sessionServiceID = Repository.GetRepositoryID(typeof(ISessionService));
      ServiceOffer[] offers = registryService.find(new String[] { sessionServiceID });
      if (offers.Length != 1)
        Log.COMMON.Warn("Existe mais de um " + sessionServiceID + " conectado.");

      IComponent component = offers[0].member;
      MarshalByRefObject ssObjRef = component.getFacet(sessionServiceID);
      if (ssObjRef == null)
        Log.COMMON.Error("Erro ao obter o SessionServiceReceptacle.");

      this.sessionService = ssObjRef as ISessionService;

      return this.sessionService;
    }

    /// <summary>
    /// Fornece a credencial interceptada a partir da requisição atual.
    /// </summary>
    /// <returns></returns>
    public Credential GetInterceptedCredential() {
      //TODO try
      OrbServices orb = OrbServices.GetSingleton();
      omg.org.PortableInterceptor.Current pic = (omg.org.PortableInterceptor.Current)orb.resolve_initial_references("PICurrent");
      Any requestCredentialValue = (Any)pic.get_slot(this.requestCredentialSlot);
      if (requestCredentialValue.Type.kind().Equals(TCKind.tk_null)) {
        //Log
        return new Credential(); //TODO invalidCredential
      }

      /*
      catch (org.omg.CORBA.UserException e)
      {
         Log.COMMON.severe("Erro ao obter a credencial da requisição,", e);
         return InvalidTypes.CREDENTIAL;
      */

      //TODO -- Testar esse método. Verificar o que get_slot retorna. é um any mesmo?

      throw new System.Exception("método não implementado");
    }

    /// <summary>
    /// Realiza uma tentativa de conexão com o barramento (serviço de controle
    /// de acesso e o serviço de registro), via nome de usuário e senha.
    /// </summary>
    /// <param name="user">O nome do usuário.</param>
    /// <param name="password">A senha.</param>
    /// <returns>O serviço de registro.</returns>
    public IRegistryService Connect(String user, String password) {
      if ((user == null) || (password == null))
        throw new ArgumentException("Os parâmetros 'user' e 'password' não podem ser nulos.");

      if (this.credential.identifier != null)
        throw new ACSLoginFailureException("O barramento já está conectado.");

      FetchACS();
      int leaseTime = -1;
      bool ok = acs.loginByPassword(user, password, out this.credential, out leaseTime);
      if (!ok)
        throw new ACSLoginFailureException("Não foi possível conectar ao barramento.");

      this.leaseRenewer = new LeaseRenewer(this.credential, this.leaseProvider);
      this.leaseRenewer.Start();

      Log.COMMON.Debug("Thread de renovação de lease está ativa. Lease = "
        + leaseTime + " segundos.");

      this.registryService = /* TODO: this.GetRegistryService(); */ acs.getRegistryService();
      return this.registryService;
    }

    /// <summary>
    /// Realiza uma tentativa de conexão com o barramento (serviço de controle
    /// de acesso e o serviço de registro), via certificado.
    /// </summary>
    /// <param name="name">O nome da entidade.</param>
    /// <param name="xmlPrivateKey">A String que representa a chave privada.</param>
    /// <param name="acsCertificate">O certificado do 
    /// serviço de controle de acesso.</param>
    /// <returns>O serviço de registro.</returns>
    public IRegistryService Connect(String name, String xmlPrivateKey,
  X509Certificate2 acsCertificate) {
      if ((name == null) || (xmlPrivateKey == null) || (acsCertificate == null))
        throw new ArgumentException("Nenhum parâmetro pode ser nulo.");

      if (this.credential.identifier != null)
        throw new ACSLoginFailureException("O barramento já está conectado.");

      FetchACS();
      byte[] challenge = this.acs.getChallenge(name);
      if (challenge.Length == 0)
        throw new ACSLoginFailureException("Desafio inválido.");

      byte[] answer;
      //try -- SecurityException
      answer = Crypto.GenerateAnswer(challenge, xmlPrivateKey, acsCertificate);

      int leaseTime = -1;
      this.acs.loginByCertificate(name, answer, out this.credential, out leaseTime);

      this.leaseRenewer = new LeaseRenewer(this.credential, this.leaseProvider);
      this.leaseRenewer.Start();

      Log.COMMON.Info("Thread de renovação de lease está ativa. Lease = "
        + leaseTime + " segundos.");
      this.registryService = /*TODO GetRegistryService();*/ acs.getRegistryService();
      return this.registryService;
    }

    /// <summary>
    /// Realiza uma tentativa de conexão com o barramento (serviço de controle
    /// de acesso e o serviço de registro).
    /// </summary>
    /// <param name="credential">A credencial</param>
    /// <returns>O serviço de registro.</returns>
    public IRegistryService Connect(Credential credential) {
      if (credential.identifier == "")
        throw new ArgumentException("O parâmetro 'credential' não pode ser nulo.");

      if (this.credential.identifier != null)
        throw new ACSLoginFailureException("O barramento já está conectado.");

      FetchACS();
      bool ok = this.acs.isValid(this.credential);
      if (!ok)
        throw new InvalidCredentialException();

      this.registryService = this.GetRegistryService();
      return this.registryService;
    }

    /// <summary>
    /// Desfaz a conexão.
    /// 
    /// {@code true} caso a conexão seja desfeita, ou {@code false} se nenhuma conexão estiver ativa.
    /// </summary>
    /// <returns><code>true</code> caso a conexão seja desfeita, ou 
    /// <code>false</code> se nenhuma conexão estiver ativa. </returns>
    public bool Disconnect() {
      bool status = false;
      if (this.credential.identifier == null)
        throw new ACSUnavailableException("O barramento não está conectado.");

      this.leaseRenewer.Finish();
      this.leaseRenewer = null;

      status = this.acs.logout(this.credential);
      if (status)
        Reset();

      return status;
    }

    /// <summary>
    /// Finaliza a utilização do barramento.
    /// </summary>
    public void Destroy() {
      ChannelServices.UnregisterChannel(channel);
      ResetInstance();
    }

    /// <summary>
    /// Informa o estado de conexão com o barramento.
    /// </summary>
    /// <returns></returns>
    public bool isConnected() {
      return (this.credential.identifier != null);
    }

    /// <summary>
    /// Atribui o observador para receber eventos de expiração do <i>lease</i>.
    /// </summary>
    /// <param name="lec">O observador.</param>
    public void AddLeaseExpiredCallback(LeaseExpiredCallback lec) {
      if (this.leaseRenewer != null)
        this.leaseRenewer.SetLeaseExpiredCallback(lec);
    }

    /// <summary>
    /// Remove o observador de expiração de <i>lease</i>.
    /// </summary>
    public void RemoveLeaseExpiredCallback() {
      if (this.leaseRenewer != null)
        this.leaseRenewer.SetLeaseExpiredCallback(null);
    }

    #endregion
  }
}
