package tecgraf.openbus.demo.data_service.valuetypes;

import tecgraf.openbus.data_service.UnstructuredData;
import tecgraf.openbus.data_service.UnstructuredDataHelper;

public class UnstructuredDataImpl extends UnstructuredData {

  public UnstructuredDataImpl() {
    this.key = new byte[0];
    this.accessKey = new byte[0];
    this.host = "";
    this.port = 0;
    this.writable = false;

  }

  public UnstructuredDataImpl(byte[] accessKey, String host, int port,
    boolean writable) {
    this.key = new byte[0];
    this.accessKey = accessKey;
    this.host = host;
    this.port = port;
    this.writable = writable;
  }

  public UnstructuredDataImpl(byte[] key, byte[] accessKey, String host,
    int port, boolean writable) {
    this(accessKey, host, port, writable);
    this.key = key;
  }

  @Override
  public String getInterfaceName() {
    return UnstructuredDataHelper.id();
  }

  @Override
  public byte[] getKey() {
    return key;
  }

}
