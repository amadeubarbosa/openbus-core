using System;


namespace OpenbusAPI.Logger
{
  /// <summary>
  /// Interface de Log do Openbus.
  /// </summary>
  public interface ILogger
  {
    /// <summary>
    /// Define o nível do log.
    /// </summary>
    /// <param name="level">O nível do log.</param>
    void SetLevel(Level level);

    /// <summary>
    /// Fornece o nível do log. 
    /// </summary>
    /// <returns>O nível do log.</returns>
    Level GetLevel();

    /// <summary>
    /// Registra uma mensagem fatal.
    /// </summary>
    /// <param name="message">A mensagem.</param>
    void Fatal(Object message);

    /// <summary>
    /// Registra uma mensagem fatal com uma exceção associada.
    /// </summary>
    /// <param name="message">A mensagem.</param>
    /// <param name="exception">A exceção</param>
    void Fatal(Object message, System.Exception exception);

    /// <summary>
    /// Registra uma mensagem de erro.
    /// </summary>
    /// <param name="message">A mensagem.</param>
    void Error(Object message);

    /// <summary>
    /// Registra uma mensagem de erro com uma exceção associada.
    /// </summary>
    /// <param name="message">A mensagem.</param>
    /// <param name="exception">A exceção.</param>
    void Error(Object message, System.Exception exception);

    /// <summary>
    /// Registra uma mensagem de warning. 
    /// </summary>
    /// <param name="message">A mensagem.</param>
    void Warn(Object message);

    /// <summary>
    /// Registra uma mensagem de warning com uma exceção associada.
    /// </summary>
    /// <param name="message">A mensagem.</param>
    /// <param name="exception">A exceção.</param>
    void Warn(Object message, System.Exception exception);

    /// <summary>
    /// Registra uma mensagem de informação.
    /// </summary>
    /// <param name="message">A mensagem.</param>
    void Info(Object message);

    /// <summary>
    /// Registra uma mensagem de informação com uma exceção associada.
    /// </summary>
    /// <param name="message">A mensagem.</param>
    /// <param name="exception">A exceção.</param>
    void Info(Object message, System.Exception exception);

    /// <summary>
    /// Registra uma mensagem de depuração.
    /// </summary>
    /// <param name="message">A mensagem.</param>
    void Debug(Object message);

    /// <summary>
    /// Registra uma mensagem depuração com uma exceção associada.
    /// </summary>
    /// <param name="message">A mensagem.</param>
    /// <param name="exception">A exceção.</param>
    void Debug(Object message, System.Exception exception);
  }

  /// <summary>
  /// Define os níveis de log do Openbus.
  /// </summary>
  public enum Level
  {
    /// <summary>
    /// Nivél fatal.
    /// </summary>
    FATAL,
    /// <summary>
    /// Nível erro
    /// </summary>
    ERROR,
    /// <summary>
    /// Nível warning
    /// </summary>
    WARN,
    /// <summary>
    /// Nível informação
    /// </summary>
    INFO,
    /// <summary>
    /// Nível depuração.
    /// </summary>
    DEBUG
  }
}
