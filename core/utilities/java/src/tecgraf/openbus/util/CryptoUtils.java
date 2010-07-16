/*
 * $Id$
 */
package tecgraf.openbus.util;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.security.GeneralSecurityException;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.security.spec.InvalidKeySpecException;
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
   * @param certificateFile O caminho para o arquivo.
   * 
   * @return O certificado carregado.
   * 
   * @throws CertificateException Caso o arquivo esteja corrompido.
   * @throws FileNotFoundException Caso o arquivo n�o exista.
   */
  public static X509Certificate readCertificate(String certificateFile)
    throws CertificateException, FileNotFoundException {
    return readCertificate(new FileInputStream(certificateFile));
  }

  /**
   * L� um certificado digital a partir de um stream de arquivo.
   * 
   * @param inputStream O stream de entrada para o arquivo.
   * 
   * @return O certificado carregado.
   * 
   * @throws CertificateException Caso o arquivo esteja corrompido.
   */
  public static X509Certificate readCertificate(InputStream inputStream)
    throws CertificateException {
    try {
      CertificateFactory cf = CertificateFactory.getInstance(CERTIFICATE_TYPE);
      return (X509Certificate) cf.generateCertificate(inputStream);
    }
    finally {
      try {
        inputStream.close();
      }
      catch (IOException e) {
        Log.COMMON.warning(e.getLocalizedMessage());
      }
    }
  }

  /**
   * L� uma chave privada a partir de um arquivo.
   * 
   * @param privateKeyFileName O caminho para o arquivo.
   * 
   * @return A chave privada carregada.
   * 
   * @throws NoSuchAlgorithmException Caso o algoritmo para cria��o da chave n�o
   *         seja encontrado.
   * @throws InvalidKeySpecException Caso o formato da chave seja inv�lido.
   * @throws InvalidKeyException Caso o formato da chave seja inv�lido.
   * @throws IOException Caso ocorra algum erro durante a leitura.
   * @throws FileNotFoundException Caso o arquivo n�o exista.
   */
  public static RSAPrivateKey readPrivateKey(String privateKeyFileName)
    throws NoSuchAlgorithmException, InvalidKeySpecException,
    InvalidKeyException, IOException, FileNotFoundException {
    return generatePrivateKey(readBytes(privateKeyFileName));
  }

  /**
   * L� uma chave privada a partir de um stream de arquivo.
   * 
   * @param inputStream O stream de entrada para o arquivo.
   * 
   * @return A chave privada carregada.
   * 
   * @throws NoSuchAlgorithmException Caso o algoritmo para cria��o da chave n�o
   *         seja encontrado.
   * @throws InvalidKeySpecException Caso o formato da chave seja inv�lido.
   * @throws InvalidKeyException Caso o formato da chave seja inv�lido.
   * @throws IOException Caso ocorra algum erro durante a leitura.
   * @throws FileNotFoundException Caso o arquivo n�o exista.
   */
  public static RSAPrivateKey readPrivateKey(InputStream inputStream)
    throws NoSuchAlgorithmException, InvalidKeySpecException,
    InvalidKeyException, IOException, FileNotFoundException {
    return generatePrivateKey(readBytes(inputStream));
  }

  /**
   * L� uma chave privada a partir de um leitor de arquivo.
   * 
   * @param reader O leitor do arquivo.
   * 
   * @return A chave privada carregada.
   * 
   * @throws NoSuchAlgorithmException Caso o algoritmo para cria��o da chave n�o
   *         seja encontrado.
   * @throws InvalidKeySpecException Caso o formato da chave seja inv�lido.
   * @throws InvalidKeyException Caso o formato da chave seja inv�lido.
   * @throws IOException Caso ocorra algum erro durante a leitura.
   * @throws FileNotFoundException Caso o arquivo n�o exista.
   */
  public static RSAPrivateKey readPrivateKey(Reader reader)
    throws NoSuchAlgorithmException, InvalidKeySpecException,
    InvalidKeyException, IOException, FileNotFoundException {
    return generatePrivateKey(readBytes(reader));
  }

  /**
   * Gera uma chave privada a partir de um vetor de bytes codificados em base
   * 64.
   * 
   * @param encodedBytes o vetor de bytes.
   * 
   * @return A chave privada carregada.
   * 
   * @throws NoSuchAlgorithmException Caso o algoritmo para cria��o da chave n�o
   *         seja encontrado.
   * @throws InvalidKeySpecException Caso o formato da chave seja inv�lido.
   */
  private static RSAPrivateKey generatePrivateKey(byte[] encodedBytes)
    throws NoSuchAlgorithmException, InvalidKeySpecException {
    Base64 base64 = new Base64();
    byte[] bytes = base64.decode(encodedBytes);
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
   * @return Os bytes representando a chave privada na base 64.
   * 
   * @throws InvalidKeyException Caso o formato da chave seja inv�lido.
   * @throws IOException Caso ocorra algum erro durante a leitura.
   * @throws FileNotFoundException Caso o arquivo n�o exista.
   */
  private static byte[] readBytes(String privateKeyFileName)
    throws InvalidKeyException, IOException, FileNotFoundException {
    return readBytes(new FileReader(privateKeyFileName));
  }

  /**
   * L� os bytes de um arquivo que representa uma chave privada, no formato
   * PKCS#8 e na base 64, retirando o seu cabe�alho e o seu rodap�.
   * 
   * @param inputStream O stream de entrada para o arquivo.
   * 
   * @return Os bytes representando a chave privada na base 64.
   * 
   * @throws InvalidKeyException Caso o formato da chave seja inv�lido.
   * @throws IOException Caso ocorra algum erro durante a leitura.
   */
  private static byte[] readBytes(InputStream inputStream)
    throws InvalidKeyException, IOException {
    return readBytes(new InputStreamReader(inputStream));
  }

  /**
   * L� os bytes de um arquivo que representa uma chave privada, no formato
   * PKCS#8 e na base 64, retirando o seu cabe�alho e o seu rodap�.
   * 
   * @param reader O leitor para o arquivo.
   * 
   * @return Os bytes representando a chave privada na base 64.
   * 
   * @throws InvalidKeyException Caso o formato da chave seja inv�lido.
   * @throws IOException Caso ocorra algum erro durante a leitura.
   */
  private static byte[] readBytes(Reader reader) throws InvalidKeyException,
    IOException {
    BufferedReader bufferedReader = new BufferedReader(reader);
    StringBuilder data = new StringBuilder();
    try {
      String line = bufferedReader.readLine();
      if (line == null || !line.equals("-----BEGIN PRIVATE KEY-----")) {
        throw new InvalidKeyException(
          "Formato do arquivo inv�lido: cabe�alho n�o encontrado.");
      }
      for (line = bufferedReader.readLine(); line != null; line =
        bufferedReader.readLine()) {
        if (line.equals("-----END PRIVATE KEY-----")) {
          return data.toString().getBytes();
        }
        data.append(line);
      }
      throw new InvalidKeyException(
        "Formato do arquivo inv�lido: rodap� n�o encontrado.");
    }
    finally {
      try {
        bufferedReader.close();
      }
      catch (IOException e) {
        // Nada a ser feito.
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
    if (certificate == null) {
      throw new IllegalArgumentException("certificate == null");
    }
    if (data == null) {
      throw new IllegalArgumentException("data == null");
    }
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
