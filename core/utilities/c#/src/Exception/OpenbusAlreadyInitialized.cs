using System;


namespace OpenbusAPI.Exception
{
  /// <summary>
  /// Indica uma exceção de Openbus já está inicializado.
  /// </summary>
  [Serializable]
  public class OpenbusAlreadyInitialized : OpenbusException
  {
    /// <inheritdoc />
    public OpenbusAlreadyInitialized() { }

    /// <inheritdoc />
    public OpenbusAlreadyInitialized(string message) : base(message) { }

    /// <inheritdoc />
    public OpenbusAlreadyInitialized(string message, System.Exception inner) 
      : base(message, inner) { }
  }
}
