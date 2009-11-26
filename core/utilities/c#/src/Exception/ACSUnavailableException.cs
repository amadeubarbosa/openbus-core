using System;


namespace OpenbusAPI.Exception
{
  /// <summary>
  /// Indica uma exceção de serviço de controle de acesso indisponível
  /// </summary>
  [Serializable]
  public class ACSUnavailableException : OpenbusException
  {
    /// <inheritdoc />
    public ACSUnavailableException() { }

    /// <inheritdoc />
    public ACSUnavailableException(string message) : base(message) { }

    /// <inheritdoc />
    public ACSUnavailableException(string message, System.Exception inner) 
      : base(message, inner) { }
  }
}
