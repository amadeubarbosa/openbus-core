using System;
using System.IO;
using System.Xml;


namespace OpenbusAPI.Logger
{
  /// <summary>
  /// Um wrapper para a Log da Apache.
  /// Implementa o OpenbusAPI.Logger.ILogger.
  /// </summary>
  class ApacheLog : ILogger
  {
    #region Fields

    /// <summary>
    /// Objeto que implementa a interfce Log4net.ILog
    /// </summary>
    private log4net.ILog log;

    #endregion

    #region Constructors

    /// <summary>
    /// Inicializa um wrapper para o Log da Apache.
    /// Utiliza o arquivo XML de configuração presente no resource.
    /// </summary>
    /// <param name="loggerName">Nome do Logger.</param>
    public ApacheLog(String loggerName) {
      XmlDocument xmlDocument = new XmlDocument();
      xmlDocument.LoadXml(Properties.Resources.LogConfigFile);

      XmlNodeList logNodeList = xmlDocument.GetElementsByTagName("log4net");
      if (logNodeList.Count != 1) {
        Console.WriteLine("O arquivo de configuração de log está incorreto.");
        return;
      }

      XmlElement xmlElemnt = logNodeList.Item(0) as XmlElement;
      log4net.Config.XmlConfigurator.Configure(xmlElemnt);

      this.log = log4net.LogManager.GetLogger(loggerName);
    }

    /// <summary>
    /// Inicializa um wrapper para o Log da Apache.
    /// Recebe o arquivo XML de configuração de log.
    /// </summary>
    /// <param name="configFileName">Caminho do arquivo XML de configuração.
    /// </param>
    /// <param name="loggerName">Nome do Logger.</param>
    public ApacheLog(String configFileName, String loggerName) {
      FileInfo file = new FileInfo(configFileName);
      log4net.Config.XmlConfigurator.Configure(file);

      this.log = log4net.LogManager.GetLogger(loggerName);
    }

    #endregion

    #region ILogger Members

    /// <inheritdoc />
    public void SetLevel(Level level) {
      log4net.Repository.Hierarchy.Logger logger = this.log.Logger as
        log4net.Repository.Hierarchy.Logger;

      switch (level) {
        case Level.DEBUG:
        logger.Level = log4net.Core.Level.Debug;
        break;
        case Level.INFO:
        logger.Level = log4net.Core.Level.Info;
        break;
        case Level.WARN:
        logger.Level = log4net.Core.Level.Warn;
        break;
        case Level.ERROR:
        logger.Level = log4net.Core.Level.Error;
        break;
        case Level.FATAL:
        logger.Level = log4net.Core.Level.Fatal;
        break;
      }
    }

    /// <inheritdoc />
    public Level GetLevel() {
      if (this.log.IsDebugEnabled)
        return Level.DEBUG;
      if (this.log.IsInfoEnabled)
        return Level.INFO;
      if (this.log.IsWarnEnabled)
        return Level.WARN;
      if (this.log.IsErrorEnabled)
        return Level.ERROR;
      if (this.log.IsFatalEnabled)
        return Level.FATAL;

      throw new NullReferenceException();
    }

    /// <inheritdoc />
    public void Fatal(object message) {
      this.log.Fatal(message);
    }

    /// <inheritdoc />
    public void Fatal(object message, System.Exception exception) {
      this.log.Fatal(message, exception);
    }

    /// <inheritdoc />
    public void Error(object message) {
      this.log.Error(message);
    }

    /// <inheritdoc />
    public void Error(object message, System.Exception exception) {
      this.log.Error(message, exception);
    }

    /// <inheritdoc />
    public void Warn(object message) {
      this.log.Warn(message);
    }

    /// <inheritdoc />
    public void Warn(object message, System.Exception exception) {
      this.log.Warn(message, exception);
    }

    /// <inheritdoc />
    public void Info(object message) {
      this.log.Info(message);
    }

    /// <inheritdoc />
    public void Info(object message, System.Exception exception) {
      this.log.Info(message, exception);
    }

    /// <inheritdoc />
    public void Debug(object message) {
      this.log.Debug(message);
    }

    /// <inheritdoc />
    public void Debug(object message, System.Exception exception) {
      this.log.Debug(message, exception);
    }

    #endregion
  }
}
