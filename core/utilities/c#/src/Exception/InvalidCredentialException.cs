using System;


namespace OpenbusAPI.Exception
{
  /// <summary>
  /// Indica uma exceção de credencial inválida
  /// </summary>
  [Serializable]
  public class InvalidCredentialException : OpenbusException
  {
    /// <inheritdoc />
    public InvalidCredentialException() { }

    /// <inheritdoc />
    public InvalidCredentialException(string message) : base(message) { }

    /// <inheritdoc />
    public InvalidCredentialException(string message, System.Exception inner) 
      : base(message, inner) { }
  }
}
