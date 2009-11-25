using System;
using System.Collections.Generic;
using System.Text;

namespace OpenbusAPI.Exception
{
  /// <summary>
  /// Indica uma exceção de credencial inválida
  /// </summary>
  [Serializable()]
  class InvalidCredentialException : OpenbusException
  {
    /// <inheritdoc />
    public InvalidCredentialException() : base() { }


    /// <inheritdoc />
    public InvalidCredentialException(string message) : base(message) { }


    /// <inheritdoc />
    public InvalidCredentialException(string message, System.Exception inner) : base(message, inner) { }
  }
}
