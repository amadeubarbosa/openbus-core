package tecgraf.openbus.demo.data_service.utils;

import java.io.UnsupportedEncodingException;

public class DataKeyManager {

  public final static String ENCODE = "UTF-8";
  public final static String SEPARATOR = "#";

  private static String serverComponentId = "";

  private String componentId;
  private String key;

  public DataKeyManager(String componentId, String key) {
    this.componentId = componentId;
    this.key = key;
  }

  public DataKeyManager(String key) {
    this.componentId = serverComponentId;
    this.key = key;
  }

  public DataKeyManager(byte[] key) {
    try {
      String dataKey = new String(key, ENCODE);
      String[] splitKey = dataKey.split(SEPARATOR);
      // TODO botar algum tratamento no splitKey
      this.componentId = splitKey[0];
      this.key = splitKey[1];
    }
    catch (UnsupportedEncodingException e) {
      e.printStackTrace();
    }
  }

  public static byte[] createDataKey(String path)
    throws UnsupportedEncodingException {
    return path.getBytes(ENCODE);
  }

  public static String getPathByDataKey(byte[] key)
    throws UnsupportedEncodingException {
    return new String(key, ENCODE);
  }

  public byte[] getDataKey() {
    try {
      String dataKey = componentId + SEPARATOR + key;
      return dataKey.getBytes(ENCODE);
    }
    catch (UnsupportedEncodingException e) {
      e.printStackTrace();
    }
    return null;
  }

  public static boolean compareDataKey(byte[] key1, byte[] key2) {
    // if (key1.ior.compareTo(key2.ior) == 0)
    for (int i = 0; i < key1.length; i++) {
      if (key1[i] != key2[i])
        return false;
    }
    return true;
  }

  public String getKey() {
    return key;
  }

  public static void setServerComponentId(String serverComponentId) {
    DataKeyManager.serverComponentId = serverComponentId;
  }

}
