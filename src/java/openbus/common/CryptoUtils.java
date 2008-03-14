/*
 * $Id$
 */
package openbus.common;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.security.GeneralSecurityException;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;

import javax.crypto.Cipher;

import org.apache.commons.codec.binary.Base64;

/**
 * M�todos utilit�rios para uso de criptografia.
 * 
 * @author Tecgraf/PUC-Rio
 */
public final class CryptoUtils {
  /**
   * O tipo de f�brica de chaves privadas utilizado.
   */
  private static final String KEY_FACTORY_TYPE = "RSA";
  /**
   * O tipo de certificado utilizado pelo OpenBus.
   */
  private static final String CERTIFICATE_TYPE = "X.509";
  /**
   * O algoritmo de criptografia (assim�trica) utilizada pelo OpenBus.
   */
  private static final String CIPHER_ALGORITHM = "RSA";

  /**
   * L� um certificado digital a partir de um arquivo.
   * 
   * @param certificateFile O nome do arquivo.
   * 
   * @return O certificado carregado, ou {@code null}, caso o arquivo n�o
   *         exista.
   * 
   * @throws CertificateException Caso o arquivo esteja corrompido.
   */
  public static X509Certificate readCertificate(String certificateFile)
    throws CertificateException {
    InputStream inputStream;
    try {
      inputStream = new FileInputStream(certificateFile);
    }
    catch (FileNotFoundException e) {
      return null;
    }
    try {
      CertificateFactory cf = CertificateFactory.getInstance(CERTIFICATE_TYPE);
      return (X509Certificate) cf.generateCertificate(inputStream);
    }
    finally {
      try {
        inputStream.close();
      }
      catch (IOException e) {
        e.printStackTrace();
      }
    }
  }

  /**
   * L� uma chave privada a partir de um arquivo.
   * 
   * @param privateKeyFileName O nome do arquivo.
   * 
   * @return A chave privada carregada, ou {@code null}, caso o arquivo n�o
   *         exista.
   * 
   * @throws IOException Caso ocorra algum erro durante a leitura.
   * @throws GeneralSecurityException Caso ocorra algum erro durante a cria��o
   *         da chave.
   */
  public static RSAPrivateKey readPrivateKey(String privateKeyFileName)
    throws IOException, GeneralSecurityException {
    byte[] encodedBuffer = readBytes(privateKeyFileName);
    if (encodedBuffer == null) {
      return null;
    }
    Base64 base64 = new Base64();
    byte[] bytes = base64.decode(encodedBuffer);
    PKCS8EncodedKeySpec encodedKey = new PKCS8EncodedKeySpec(bytes);
    KeyFactory kf = KeyFactory.getInstance(KEY_FACTORY_TYPE);
    return (RSAPrivateKey) kf.generatePrivate(encodedKey);
  }

  /**
   * 
   * L� os bytes de um arquivo que representa uma chave privada, no formato
   * PKCS#8 e na base 64, retirando o seu cabe�alho e o seu rodap�.
   * 
   * @param privateKeyFileName O nome (caminho completo) do arquivo contendo a
   *        chave privada.
   * 
   * @return Os bytes representando a chave privada na base 64, ou {@code null},
   *         caso o arquivo n�o exista.
   * 
   * @throws IOException Caso ocorra algum erro durante a leitura.
   */
  private static byte[] readBytes(String privateKeyFileName) throws IOException {
    BufferedReader reader;
    try {
      reader = new BufferedReader(new FileReader(privateKeyFileName));
    }
    catch (FileNotFoundException e) {
      return null;
    }
    StringBuilder data = new StringBuilder();
    try {
      String line = reader.readLine();
      if (line == null || !line.equals("-----BEGIN PRIVATE KEY-----")) {
        throw new IOException(
          "Formato do arquivo inv�lido: cabe�alho n�o encontrado.");
      }
      for (line = reader.readLine(); line != null; line = reader.readLine()) {
        if (line.equals("-----END PRIVATE KEY-----")) {
          return data.toString().getBytes();
        }
      }
      throw new IOException(
        "Formato do arquivo inv�lido: rodap� n�o encontrado.");
    }
    finally {
      try {
        reader.close();
      }
      catch (IOException e) {
      }
    }
  }

  /**
   * Criptografa dados.
   * 
   * @param certificate O certificado digital de onde ser� extra�do a chave
   *        p�blica para criptografar os dados.
   * 
   * @param data Os dados.
   * 
   * @return O texto criptografado.
   * 
   * @throws GeneralSecurityException Caso ocorra alguma falha com o
   *         procedimento.
   */
  public static byte[] encrypt(Certificate certificate, byte[] data)
    throws GeneralSecurityException {
    Cipher cipher = Cipher.getInstance(CIPHER_ALGORITHM);
    cipher.init(Cipher.ENCRYPT_MODE, certificate);
    return cipher.doFinal(data);
  }

  /**
   * Gera o texto plano a partir de um texto previamente criptografado.
   * 
   * @param privateKey A chave privada utilizada para gerar o texto plano (deve
   *        ser a chave correspondente � chave p�blica utilizada para gerar o
   *        texto criptografado).
   * @param encryptedData O texto criptografado.
   * 
   * @return O texto plano.
   * 
   * @throws GeneralSecurityException Caso ocorra alguma falha com o
   *         procedimento.
   */
  public static byte[] decrypt(PrivateKey privateKey, byte[] encryptedData)
    throws GeneralSecurityException {
    Cipher cipher = Cipher.getInstance(CIPHER_ALGORITHM);
    cipher.init(Cipher.DECRYPT_MODE, privateKey);
    return cipher.doFinal(encryptedData);
  }
}
