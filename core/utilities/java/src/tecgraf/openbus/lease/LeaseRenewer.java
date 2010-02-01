/*
 * $Id$
 */
package tecgraf.openbus.lease;

import java.util.Date;

import openbusidl.acs.Credential;
import openbusidl.acs.ILeaseProvider;

import org.omg.CORBA.IntHolder;
import org.omg.CORBA.NO_PERMISSION;
import org.omg.CORBA.SystemException;

import tecgraf.openbus.util.Log;

/**
 * Responsável por renovar um lease junto a um provedor.
 * 
 * @author Tecgraf/PUC-Rio
 */
public final class LeaseRenewer {
  private static final int DEFAULT_LEASE = 30;
  /**
   * O provedor onde o <i>lease</i> deve ser renovado.
   */
  private ILeaseProvider leaseProvider;
  /**
   * A tarefa responsável por renovar um <i>lease</i>.
   */
  private RenewerTask renewer;

  /**
   * Cria um renovador de <i>lease</i> junto a um provedor.
   * 
   * @param credential A credencial que deve ser renovada.
   * @param leaseProvider O provedor onde o <i>lease</i> deve ser renovado.
   * @param openbusCallback <i>Callback</i> usada para atualizar o estado do
   *        Openbus quando uma renovação de um <i>lease</i> falhou.
   * @param userCallback <i>Callback</i> usada para informar que a renovação de
   *        um <i>lease</i> falhou.
   */
  public LeaseRenewer(Credential credential, ILeaseProvider leaseProvider,
    LeaseExpiredCallback openbusCallback, LeaseExpiredCallback userCallback) {
    this.leaseProvider = leaseProvider;
    this.renewer =
      new RenewerTask(credential, this.leaseProvider, openbusCallback,
        userCallback);
  }

  /**
   * Define o provedor onde o <i>lease</i> deve ser renovado.
   * 
   * @param leaseProvider O provedor onde o <i>lease</i> deve ser renovado.
   */
  public void setProvider(ILeaseProvider leaseProvider) {
    this.leaseProvider = leaseProvider;
    this.renewer.setProvider(this.leaseProvider);
  }

  /**
   * Define o observador do <i>lease</i>.
   * 
   * @param lec O observador do <i>lease</i>.
   */
  public void setLeaseExpiredCallback(LeaseExpiredCallback lec) {
    this.renewer.userExpiredCallback = lec;
  }

  /**
   * Inicia uma renovação de <i>lease</i>.
   */
  public void start() {
    this.renewer.start();
  }

  /**
   * Solicita o fim da renovação do <i>lease</i>.
   */
  public void finish() {
    this.renewer.finish();
  }

  /**
   * Tarefa responsável por renovar um <i>lease</i>.
   * 
   * @author Tecgraf/PUC-Rio
   */
  private static class RenewerTask extends Thread {
    /**
     * A credencial correspondente ao <i>lease</i>.
     */
    private Credential credential;
    /**
     * O provedor do <i>lease</i>.
     */
    private ILeaseProvider provider;
    /**
     * <i>Callback</i> usada para atualizar o estado do Openbus quando uma
     * renovação de um <i>lease</i> falhou.
     */
    private LeaseExpiredCallback openbusExpiredCallback;
    /**
     * <i>Callback</i> usada para informar que a renovação de um <i>lease</i>
     * falhou.
     */
    private LeaseExpiredCallback userExpiredCallback;
    /**
     * Indica se a <i>thread</i> deve continuar executando.
     */
    private boolean mustContinue;

    /**
     * Cria uma tarefa para renovar um <i>lease</i>.
     * 
     * @param credential A credencial correspondente ao <i>lease</i>.
     * @param provider O provedor do <i>lease</i>.
     * 
     */
    RenewerTask(Credential credential, ILeaseProvider provider) {
      this.credential = credential;
      this.provider = provider;
      this.mustContinue = true;
    }

    /**
     * Cria uma tarefa para renovar um <i>lease</i>.
     * 
     * @param credential A credencial correspondente ao <i>lease</i>.
     * @param provider O provedor do <i>lease</i>.
     * @param openbusCallback <i>Callback</i> usada para atualizar o estado do
     *        Openbus quando uma renovação de um <i>lease</i> falhou.
     * @param userCallback <i>Callback</i> usada para informar que a renovação
     *        de um <i>lease</i> falhou.
     */
    RenewerTask(Credential credential, ILeaseProvider provider,
      LeaseExpiredCallback openbusCallback, LeaseExpiredCallback userCallback) {
      this(credential, provider);
      this.userExpiredCallback = userCallback;
      this.openbusExpiredCallback = openbusCallback;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void run() {
      int lease = DEFAULT_LEASE;

      while (this.mustContinue) {
        IntHolder newLease = new IntHolder();

        try {
          boolean expired;
          try {
            expired = !(this.provider.renewLease(this.credential, newLease));
          }
          catch (NO_PERMISSION ne) {
            expired = true;
          }

          if (expired) {
            Log.LEASE.warning("Falha na renovação da credencial.");
            this.openbusExpiredCallback.expired();
            if (this.userExpiredCallback != null) {
              this.userExpiredCallback.expired();
            }
            this.mustContinue = false;
          }
          else {
            StringBuilder msg = new StringBuilder();
            msg.append(new Date());
            msg.append(" - Lease renovado. Próxima renovação em ");
            msg.append(newLease.value);
            msg.append(" segundos.");
            Log.LEASE.fine(msg.toString());
            lease = newLease.value;
          }
        }
        catch (SystemException e) {
          Log.LEASE.severe(e.getMessage(), e);
        }

        if (this.mustContinue) {
          try {
            Thread.sleep(lease * 1000);
          }
          catch (InterruptedException e) {
            // Nada a ser feito.
          }
        }
      }
    }

    /**
     * Finaliza o renovador de <i>lease</i>.
     */
    public void finish() {
      this.mustContinue = false;
    }

    /**
     * Define o provedor do <i>lease</i>.
     * 
     * @param provider O provedor do <i>lease</i>.
     */
    public void setProvider(ILeaseProvider provider) {
      this.provider = provider;
    }
  }
}
