using openbusidl.acs;
using System.Threading;


namespace OpenbusAPI.Lease
{
  /// <summary>
  /// Classe responsável por renovar o <i>lease</i>.
  /// </summary>
  class LeaseRenewer
  {
    #region Fields

    /// <summary>
    /// O renovador de lease.
    /// </summary>
    private RenewerTask renewer;

    /// <summary>
    /// A thread responsável por renovar o <i>lease</i>.
    /// </summary>
    private Thread leaseThread;

    #endregion

    #region Constructors

    /// <summary>
    /// Inicializa um renovador de <i>lease</i>.
    /// </summary>
    /// <param name="credential">A credencial correspondente ao <i>lease</i>.
    /// </param>
    /// <param name="leaseProvider">Faceta do serviço de controle de acesso.>
    /// </param>
    /// <param name="leaseExpiredCallback"><i>Callback</i> usada para informar 
    /// que a renovaçãode um <i>lease</i> falhou.</param>
    public LeaseRenewer(Credential credential, ILeaseProvider leaseProvider,
      LeaseExpiredCallback leaseExpiredCallback) {
      this.renewer = new RenewerTask(credential, leaseProvider);
      this.leaseThread = new Thread(new ThreadStart(renewer.Run));
      this.leaseThread.Name = "LeaseRenewer";
      this.leaseThread.IsBackground = true;
      this.renewer.ExpiredCallback = leaseExpiredCallback;
    }

    #endregion

    #region Members

    /// <summary>
    /// Define o observador do <i>lease</i>. 
    /// </summary>
    /// <param name="leaseExpiredCallback">O observador do <i>lease</i>.</param>
    public void SetLeaseExpiredCallback(LeaseExpiredCallback leaseExpiredCallback) {
      this.renewer.ExpiredCallback = leaseExpiredCallback;
    }

    /// <summary>
    /// Inicia uma renovação de <i>lease</i>.
    /// </summary>
    public void Start() {
      this.leaseThread.Start();
    }

    /// <summary>
    /// Solicita o fim da renovação do <i>lease</i>.
    /// </summary>
    public void Finish() {
      this.renewer.Finish();
      this.renewer = null;
      this.leaseThread.Interrupt();
    }

    #endregion
  }
}
