using System;


namespace OpenbusAPI.Exception
{
  /// <summary>
  /// Indica uma exceção do OpenBus.
  /// </summary>
  [Serializable]
  public class OpenbusException : ApplicationException
  {
    /// <summary>
    /// Cria uma execeção do Openbus
    /// </summary>
    public OpenbusException() { }
    
    /// <summary>
    /// Cria uma exceção do OpenBus com uma mensagem associada.
    /// </summary>
    /// <param name="message">A mensagem de erro</param>
    public OpenbusException(string message) : base(message) { }

    /// <summary>
    /// Cria uma exceção do OpenBus com uma mensagem e uma causa associada.
    /// </summary>
    /// <param name="message">A mensagem de erro</param>
    /// <param name="inner">A exceção associada</param>
    public OpenbusException(string message, System.Exception inner) 
      : base(message, inner) { }
  }
}
