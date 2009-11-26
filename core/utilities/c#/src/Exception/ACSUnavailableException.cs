using System;
using System.Collections.Generic;
using System.Text;

namespace OpenbusAPI.Exception
{
  /// <summary>
  /// Indica uma exceção de serviço de controle de acesso indisponível
  /// </summary>
  [Serializable()]
  public class ACSUnavailableException : OpenbusException
  {
    /// <inheritdoc />
    public ACSUnavailableException() : base() { }


    /// <inheritdoc />
    public ACSUnavailableException(string message) : base(message) { }


    /// <inheritdoc />
    public ACSUnavailableException(string message, System.Exception inner) : base(message, inner) { }
  }
}
