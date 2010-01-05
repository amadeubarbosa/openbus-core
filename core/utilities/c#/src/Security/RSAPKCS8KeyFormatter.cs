using System;
using System.Security.Cryptography;
using System.Text;
using System.IO;
using OpenbusAPI.Logger;

namespace OpenbusAPI.Security
{
  /// <summary>
  /// Código retirado de um exemplo do <i>Java Science Consulting</i>
  /// Link: <u>http://www.jensign.com/opensslkey/index.html</u>
  /// </summary>
  static class RSAPKCS8KeyFormatter
  {

    #region Consts

    /// <summary>
    /// Cabeçalho da chave privada.
    /// </summary>
    private const String pemHeader = "-----BEGIN PRIVATE KEY-----";
    /// <summary>
    /// Rodapé da chave privada.
    /// </summary>
    private const String pemFooter = "-----END PRIVATE KEY-----";
    /// <summary>
    /// Tamanho da chave privada.
    /// </summary>
    private const int KEY_LENGTH = 2048;

    /// <summary>
    /// Encoded OID sequence for  PKCS #1 rsaEncryption szOID_RSA_RSA = "1.2.840.113549.1.1.1".
    /// This byte[] includes the sequence byte and terminal encoded null.
    /// </summary>
    private static readonly byte[] SeqOID = { 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01, 0x05, 0x00 };

    #endregion

    #region Members
    
    /// <summary>
    /// Decodifica a chave RSA PKCS#8.
    /// </summary>
    /// <param name="pemstr">A chave em formato texto.</param>
    /// <returns>Uma instância de RSACryptoServiceProvider.</returns>
    public static RSACryptoServiceProvider DecodePEMKey(String pemText) {
      if (!pemText.StartsWith(pemHeader) || !pemText.EndsWith(pemFooter)) {
        Log.CRYPTO.Fatal("Arquivo em formato errado.");
        return null;
      }

      Log.CRYPTO.Debug("Decodificando e analisando como PEM PKCS #8 PrivateKeyInfo");
      byte[] pkcs8privatekey = DecodePkcs8PrivateKey(pemText);
      if (pkcs8privatekey == null) {
        Log.CRYPTO.Fatal("Erro ao gerar o binário da chave privada");
        return null;
      }

      Log.CRYPTO.Debug("Criando a instancia de RSACryptoServiceProvider");
      RSACryptoServiceProvider rsa = DecodePrivateKeyInfo(pkcs8privatekey);
      if (rsa == null) {
        Log.CRYPTO.Fatal("Erro ao decodificar a chave privada");
        return null;
      }

      return rsa;
    }

    /// <summary>
    /// Converte a chave RSA em XML.
    /// </summary>
    /// <param name="rsa">A chave RSA.</param>
    /// <returns>O xml que representa a chave.</returns>
    public static String RSAToXml(RSACryptoServiceProvider rsa) {
      String xmlprivatekey = rsa.ToXmlString(true);
      if (rsa.KeySize != KEY_LENGTH) {
        String errorMessage =
          String.Format("Chave não possui tamanho de {0} bits", KEY_LENGTH);
        Log.CRYPTO.Fatal(errorMessage);
        return null;
      }

      return xmlprivatekey;
    }

    #endregion

    #region Internal Members

    /// <summary>
    /// Decodifica a chave privada para binário.
    /// </summary>
    /// <param name="instr">A chave em formato texto.</param>
    /// <returns>O binário que representa a chave.</returns>
    private static byte[] DecodePkcs8PrivateKey(String instr) {
      String pemstr = instr.Trim();
      StringBuilder plainText = new StringBuilder(pemstr);

      plainText.Replace(pemHeader, "");
      plainText.Replace(pemFooter, "");

      String key = plainText.ToString().Trim();
      byte[] binaryKey;

      try {
        binaryKey = Convert.FromBase64String(key);
      }
      catch (FormatException) {
        return null;
      }
      return binaryKey;
    }

    /// <summary>
    /// Parses binary asn.1 PKCS #8 PrivateKeyInfo.
    /// </summary>
    /// <param name="pkcs8">O binário que representa a chave.</param>
    /// <returns>Uma instância de RSACryptoServiceProvider.</returns>
    private static RSACryptoServiceProvider DecodePrivateKeyInfo(byte[] pkcs8) {
      MemoryStream stream = new MemoryStream(pkcs8);
      BinaryReader binFile = new BinaryReader(stream);

      try {
        ushort twobytes = binFile.ReadUInt16();
        //data read as little endian order (actual data order for Sequence is 30 81)
        switch (twobytes) {
          case 0x8130:
            binFile.ReadByte();
            break;
          case 0x8230:
            binFile.ReadInt16();
            break;
          default:
            return null;
        }

        byte bt = binFile.ReadByte();
        if (bt != 0x02)
          return null;

        twobytes = binFile.ReadUInt16();
        if (twobytes != 0x0001)
          return null;

        Log.CRYPTO.Debug("Lendo a sequência OID.");
        byte[] seq = binFile.ReadBytes(15);

        if (!CompareByteArrays(seq, SeqOID)) {
          Log.CRYPTO.Fatal("A sequenceia OID não está correta.");
          return null;
        }

        bt = binFile.ReadByte();
        if (bt != 0x04)
          return null;

        bt = binFile.ReadByte();
        if (bt == 0x81)
          binFile.ReadByte();
        else if (bt == 0x82)
          binFile.ReadUInt16();

        Log.CRYPTO.Debug("Lendo a chave propriamente dita.");
        byte[] rsaPrivateKey = binFile.ReadBytes((int)(stream.Length - stream.Position));
        RSACryptoServiceProvider rsacsp = DecodeRSAPrivateKey(rsaPrivateKey);
        return rsacsp;
      }
      catch (System.Exception e) {
        Log.CRYPTO.Fatal("Erro ao decodificar a chave.", e);
        return null;
      }
      finally {
        binFile.Close();
      }
    }

    /// <summary>
    /// Compara <i>arrays</i> de bytes.
    /// </summary>
    /// <param name="a"><i>Array</i> 1.</param>
    /// <param name="b"><i>Array</i> 2.</param>
    /// <returns>Retorna <code>true</code> caso os <i>arrays</i> sejam iguais. 
    /// <code>False</code> caso contrário.</returns>
    private static bool CompareByteArrays(byte[] a, byte[] b) {
      if (a.Length != b.Length)
        return false;
      int i = 0;
      foreach (byte c in a) {
        if (c != b[i])
          return false;
        i++;
      }
      return true;
    }


    /// <summary>
    /// Parses binary ans.1 RSA private key.
    /// </summary>
    /// <param name="privkey">O binário que representa a chave RSA.</param>
    /// <returns>Uma instancia de RSACryptoServiceProvider.</returns>
    private static RSACryptoServiceProvider DecodeRSAPrivateKey(byte[] privkey) {
      MemoryStream stream = new MemoryStream(privkey);
      BinaryReader binFile = new BinaryReader(stream);

      try {
        ushort twobytes = binFile.ReadUInt16();
        //data read as little endian order (actual data order for Sequence is 30 81)
        switch (twobytes) {
          case 0x8130:
            binFile.ReadByte();
            break;
          case 0x8230:
            binFile.ReadInt16();
            break;
          default:
            return null;
        }

        twobytes = binFile.ReadUInt16();
        if (twobytes != 0x0102)	//version number
          return null;

        byte bt = binFile.ReadByte();
        if (bt != 0x00)
          return null;

        Log.CRYPTO.Debug("Criando a instancia de RSACryptoServiceProvider e inicializando-a");
        RSACryptoServiceProvider RSA = new RSACryptoServiceProvider();
        RSAParameters RSAparams = new RSAParameters();

        int elems = GetDataSize(binFile);
        RSAparams.Modulus = binFile.ReadBytes(elems);

        elems = GetDataSize(binFile);
        RSAparams.Exponent = binFile.ReadBytes(elems);

        elems = GetDataSize(binFile);
        RSAparams.D = binFile.ReadBytes(elems);

        elems = GetDataSize(binFile);
        RSAparams.P = binFile.ReadBytes(elems);

        elems = GetDataSize(binFile);
        RSAparams.Q = binFile.ReadBytes(elems);

        elems = GetDataSize(binFile);
        RSAparams.DP = binFile.ReadBytes(elems);

        elems = GetDataSize(binFile);
        RSAparams.DQ = binFile.ReadBytes(elems);

        elems = GetDataSize(binFile);
        RSAparams.InverseQ = binFile.ReadBytes(elems);

        RSA.ImportParameters(RSAparams);
        return RSA;
      }
      catch (System.Exception) {
        return null;
      }
      finally {
        binFile.Close();
      }
    }

    /// <summary>
    /// Fornece o tamanho do dado.
    /// </summary>
    /// <param name="binr"></param>
    /// <returns></returns>
    private static int GetDataSize(BinaryReader binr) {
      byte bt = binr.ReadByte();
      if (bt != 0x02)
        return 0;
      bt = binr.ReadByte();

      //Get de data size
      int count = 0;
      switch (bt) {
        case 0x81:
          count = binr.ReadByte();
          break;
        case 0x82:
          byte highbyte = binr.ReadByte();
          byte lowbyte = binr.ReadByte();
          byte[] modint = { lowbyte, highbyte, 0x00, 0x00 };
          count = BitConverter.ToInt32(modint, 0);
          break;
        default:
          count = bt;
          break;
      }

      //remove high order zeros in data
      while (binr.ReadByte() == 0x00) {
        count -= 1;
      }

      //last ReadByte wasn't a removed zero, so back up a byte
      binr.BaseStream.Seek(-1, SeekOrigin.Current);
      return count;
    }

    #endregion

  }
}
