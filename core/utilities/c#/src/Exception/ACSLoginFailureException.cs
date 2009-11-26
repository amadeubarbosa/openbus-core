using System;


namespace OpenbusAPI.Exception
{
  /// <summary>
  /// Indica uma execeção de falha no serviço de controle de acesso. 
  /// </summary>
  [Serializable]
  public class ACSLoginFailureException : OpenbusException
  {
    /// <inheritdoc />
    public ACSLoginFailureException() { }
    
    /// <inheritdoc />
    public ACSLoginFailureException(string message) : base(message) { }
    
    /// <inheritdoc />
    public ACSLoginFailureException(string message, System.Exception inner) 
      : base(message, inner) { }
  }
}
