/*
 * $Id$
 */
package openbus.common;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;

import openbusidl.acs.CredentialHolder;
import openbusidl.acs.IAccessControlService;

import org.omg.CORBA.IntHolder;
import org.omg.CORBA.ORB;

/**
 * Gerenciador de conex�es das entidades que se autenticam atrav�s de
 * certificados digitais.
 * 
 * @author Tecgraf/PUC-Rio
 */
public final class ServiceConnectionManager extends ConnectionManager {
  /**
   * O nome da entidade que est� criando o gerenciador.
   */
  private String entityName;
  /**
   * A chave privada da entidade.
   */
  private PrivateKey privateKey;
  /**
   * O certificado do Servi�o de Controle de Acesso.
   */
  private Certificate acsCertificate;

  /**
   * Cria um gerenciador de conex�es.
   * 
   * @param orb O ORB utilizado para obter o Servi�o de Controle de Acesso.
   * @param host A m�quina onde se encontra o Servi�o de Controle de Acesso.
   * @param port A porta onde se encontra o Servi�o de Controle de Acesso.
   * @param entityName O nome da entidade que est� criando o gerenciador.
   * @param privateKeyFile A chave privada da entidade.
   * @param acsCertificateFile O certificado do Servi�o de Controle de Acesso.
   * @param expiredCallback <i>Callback</i> usada para informar que a renova��o
   *        de um <i>lease</i> falhou.
   * 
   * @throws IOException Caso ocorra algum erro ao ler o arquivo de chave
   *         privada.
   * @throws GeneralSecurityException Caso ocorra algum erro ao abrir o arquivo
   *         de chave privada ou de certificado.
   */
  public ServiceConnectionManager(ORB orb, String host, int port,
    String entityName, String privateKeyFile, String acsCertificateFile,
    LeaseExpiredCallback expiredCallback) throws IOException,
    GeneralSecurityException {
    super(orb, host, port, expiredCallback);
    this.entityName = entityName;
    try {
      this.privateKey = CryptoUtils.readPrivateKey(privateKeyFile);
    }
    catch (IOException e) {
      Log.COMMON.severe("Erro ao ler o arquivo de chave privada.", e);
      throw e;
    }
    catch (GeneralSecurityException e) {
      Log.COMMON.severe("Erro ao abrir o arquivo de chave privada.", e);
      throw e;
    }
    try {
      this.acsCertificate = CryptoUtils.readCertificate(acsCertificateFile);
    }
    catch (CertificateException e) {
      Log.COMMON.severe("Erro ao ler o arquivo do certificado digital.", e);
      throw e;
    }
  }

  @Override
  protected boolean doLogin() {
    IAccessControlService acs = Utils.fetchAccessControlService(this.getORB(),
      this.getHost(), this.getPort());
    byte[] challenge = acs.getChallenge(this.entityName);
    byte[] answer;
    try {
      answer = Utils.generateAnswer(challenge, this.privateKey,
        this.acsCertificate);
    }
    catch (GeneralSecurityException e) {
      Log.COMMON
        .severe(
          "Erro ao gerar a resposta para o desafio do Servi�o de Controle de Acesso.",
          e);
      return false;
    }
    CredentialHolder credentialHolder = new CredentialHolder();
    IntHolder leaseHolder = new IntHolder();
    if (!acs.loginByCertificate(this.entityName, answer, credentialHolder,
      leaseHolder)) {
      return false;
    }
    this.setAccessControlService(acs);
    this.setCredential(credentialHolder.value);
    return true;
  }
}