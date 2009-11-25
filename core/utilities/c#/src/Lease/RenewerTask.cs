using System;
using System.Collections.Generic;
using System.Text;
using openbusidl.acs;
using OpenbusAPI.Lease;
using System.Threading;
using OpenbusAPI.Logger;

namespace OpenbusAPI.Lease
{
  /// <summary>
  /// Tarefa responsável por renovar o <i>lease</i> perante o serviço de controle de acesso.
  /// </summary>
  class RenewerTask
  {
    #region Fields

    /// <summary>
    /// A credencial.
    /// </summary>
    private Credential credential;

    /// <summary>
    /// A faceta do serviço de controle de acesso provedora de <i>lease</i>.
    /// </summary>
    private ILeaseProvider leaseProvider;

    /// <summary>
    /// <i>Callback</i> usada para informar que a renovação de um <i>lease</i>
    /// falhou.
    /// </summary>
    public LeaseExpiredCallback ExpiredCallback {
      set { expiredCallback = value; }
    }
    private LeaseExpiredCallback expiredCallback;

    /// <summary>
    /// Indica se a <i>thread</i> deve continuar executando.
    /// </summary>
    private bool mustContinue;

    #endregion


    #region Constructors

    /// <summary>
    /// Inicializa uma instância de renovação de <i>lease</i>.
    /// </summary>
    /// <param name="credential">A credencial.</param>
    /// <param name="provider">A faceta do serviço de controle de acesso provedora de <i>lease</i>.</param>
    public RenewerTask(Credential credential, ILeaseProvider provider) {
      this.credential = credential;
      this.leaseProvider = provider;
      this.expiredCallback = null;
      this.mustContinue = true;
    }

    #endregion

    #region Members

    /// <summary>
    /// Inicia a renovação de lease.
    /// </summary>
    public void Run() {
      bool ok = false;
      int newLease = -1;
      while (this.mustContinue) {
        try {
          ok = this.leaseProvider.renewLease(this.credential, out newLease);
          if (!ok) {
            Log.LEASE.Warn("Falha na renovação da credencial.");
            this.expiredCallback.expired();
            return;
          }
        }
        catch (System.Exception e) {
          Log.LEASE.Error("Erro ao tentar renovar o lease", e);
        }

        StringBuilder msg = new StringBuilder();
        msg.Append(DateTime.Now);
        msg.Append(" - Lease renovado. Próxima renovação em ");
        msg.Append(newLease + " segundos.");
        Log.LEASE.Debug(msg.ToString());

        Thread.Sleep(newLease * 1000);
      }
    }

    /// <summary>
    /// Solicita o fim da renovação do <i>lease</i>.
    /// </summary>
    public void Finish() {
      this.mustContinue = false;
    }

    #endregion
  }
}
