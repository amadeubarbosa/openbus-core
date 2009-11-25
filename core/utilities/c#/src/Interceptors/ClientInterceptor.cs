using System;
using System.Collections.Generic;
using System.Text;
using openbusidl.acs;
using omg.org.IOP;
using omg.org.CORBA;
using OpenbusAPI.Logger;

namespace OpenbusAPI.Interceptors
{
  /// <summary>
  /// Representa o interceptador cliente.
  /// Implementa PortableInterceptor.ClientRequestInterceptor.
  /// </summary>
  class ClientInterceptor : InterceptorImpl, omg.org.PortableInterceptor.ClientRequestInterceptor
  {

    #region Fields

    /// <summary>
    /// Instância do barramento.
    /// </summary>
    private Openbus bus;

    #endregion

    #region Contructor

    /// <summary>
    /// Inicializa uma nova instância de OpenbusAPI.Interceptors.ClientInterceptor
    /// </summary>
    /// <param name="codec">Codificador</param>
    public ClientInterceptor(Codec codec)
      : base("ClientInterceptor", codec) {
      this.bus = Openbus.GetInstance();
    }

    #endregion

    #region ClientRequestInterceptor Members

    /// <summary>
    /// Intercepta o request para inserção de informação de contexto.
    /// </summary>
    /// <remarks>Informação do cliente</remarks>
    public void send_request(omg.org.PortableInterceptor.ClientRequestInfo ri) {
      Log.INTERCEPTORS.Debug("executando método: " + ri.operation);
      
      /* Verifica se existe uma credencial para envio */
      Credential credential = bus.Credential;
      if ((credential.identifier == null) || (credential.identifier.Equals(""))) {
        Log.INTERCEPTORS.Info("Sem Credencial!");
        return;
      }

      Log.INTERCEPTORS.Debug("Tem Credencial");

      byte[] value = null;
      try {
        value = this.Codec.encode_value(credential);
      }
      catch {
        Log.INTERCEPTORS.Fatal("Erro na codificação da credencial.");
      }

      ri.add_request_service_context(new ServiceContext(CONTEXT_ID, value), false);
    }

    #endregion

    #region ClientRequestInterceptor Not Implemented

    public void receive_exception(omg.org.PortableInterceptor.ClientRequestInfo ri) {
      //Nada a ser feito;
    }

    public void receive_other(omg.org.PortableInterceptor.ClientRequestInfo ri) {
      //Nada a ser feito;
    }

    public void receive_reply(omg.org.PortableInterceptor.ClientRequestInfo ri) {
      //Nada a ser feito;
    }

    public void send_poll(omg.org.PortableInterceptor.ClientRequestInfo ri) {
      //Nada a ser feito;
    }

    #endregion

  }
}
