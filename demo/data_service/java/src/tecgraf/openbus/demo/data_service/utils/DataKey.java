/*
 * $Id$
 */
package tecgraf.openbus.demo.data_service.utils;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.util.Arrays;

import scs.core.ComponentId;
import tecgraf.openbus.data_service.InvalidDataKey;

/**
 * Representa a chave unívoca de um dado. A chave unívoca é composta por 5
 * elementos:
 * <ul>
 * <li>O identificador do dado dentro de seu serviço de origem.</li>
 * <li>O nome da interface de seu serviço de origem.</li>
 * <li>O identificador do componente de seu serviço de origem.</li>
 * <li>O nome da faceta do componente de seu serviço de origem.</li>
 * <li>O IOR da faceta do componente de seu serviço de origem.</li>
 * </ul>
 * 
 * Apenas o identificador do dado no seu serviço de origem é obrigatório.
 * 
 * @author Tecgraf/PUC-Rio
 */
public final class DataKey {
  private static final int BUFFER_SIZE = 1024;
  private static final String CHARSET_NAME = "UTF8";
  private static final String COMPONENT_ID_SEPARATOR = ":";
  private static final String COMPONENT_ID_VERSION_SEPARATOR = ".";

  private byte[] key;

  private String dataId;
  private String serviceInterfaceName;
  private ComponentId serviceComponentId;
  private String serviceFacetName;
  private String serviceFacetIOR;

  public DataKey(byte[] key) throws InvalidDataKey {
    ByteBuffer buffer = ByteBuffer.wrap(key);
    try {
      this.dataId = readString(buffer);
      this.serviceInterfaceName = readString(buffer);
      this.serviceComponentId = generateComponentId(readString(buffer));
      this.serviceFacetName = readString(buffer);
      this.serviceFacetIOR = readString(buffer);
      if (buffer.remaining() != 0) {
        throw new InvalidDataKey(key);
      }
    }
    catch (UnsupportedEncodingException e) {
      throw new InvalidDataKey(key);
    }
    this.key = Arrays.copyOf(key, key.length);
  }

  public DataKey(String dataId) throws InvalidDataKey {
    this(dataId, "", null, "", "");
  }

  /**
   * Cria a chave unívoca de um dado.
   * 
   * @param dataId O identificador real do dado.
   * @param serviceInterfaceName
   * @param serviceComponentId O identificador do componente de origem do dado.
   * @param serviceFacetName
   * @param serviceFacetIOR
   * @throws InvalidDataKey
   */
  public DataKey(String dataId, String serviceInterfaceName,
    ComponentId serviceComponentId, String serviceFacetName,
    String serviceFacetIOR) throws InvalidDataKey {
    if (dataId == null) {
      throw new IllegalArgumentException(
        "O identificador real do dado não pode ser nulo.");
    }
    this.dataId = dataId;

    this.serviceInterfaceName =
      serviceInterfaceName == null ? "" : serviceInterfaceName;
    this.serviceComponentId = serviceComponentId;

    this.serviceFacetName = serviceFacetName == null ? "" : serviceFacetName;
    this.serviceFacetIOR = serviceFacetIOR == null ? "" : serviceFacetIOR;

    ByteBuffer buffer = ByteBuffer.allocate(BUFFER_SIZE);

    try {
      putString(buffer, this.dataId);
      putString(buffer, this.serviceInterfaceName);
      putString(buffer, generateComponentIdString(this.serviceComponentId));
      putString(buffer, this.serviceFacetName);
      putString(buffer, this.serviceFacetIOR);
    }
    catch (UnsupportedEncodingException e) {
      throw new InvalidDataKey();
    }

    buffer.flip();
    this.key = new byte[buffer.limit()];
    buffer.get(this.key);
  }

  private static String readString(ByteBuffer byteBuffer)
    throws UnsupportedEncodingException {
    int valueLength = byteBuffer.getInt();
    byte[] value = new byte[valueLength];
    byteBuffer.get(value);
    return new String(value, CHARSET_NAME);
  }

  private static void putString(ByteBuffer byteBuffer, String value)
    throws UnsupportedEncodingException {
    byte[] valueBytes = value.getBytes(CHARSET_NAME);
    byteBuffer.putInt(valueBytes.length);
    byteBuffer.put(valueBytes);
  }

  private static ComponentId generateComponentId(String componentIdString) {
    if (componentIdString.equals("")) {
      return null;
    }
    return null;
  }

  /**
   * Gera uma string representando o identificador do componente de origem do
   * dado.
   * 
   * @param componentId O identificador do componente do dado.
   * 
   * @return Uma string representando o identificador do componente de origem do
   *         dado.
   */
  private static String generateComponentIdString(ComponentId componentId) {
    if (componentId == null) {
      return "";
    }
    return componentId.name + COMPONENT_ID_SEPARATOR
      + componentId.major_version + COMPONENT_ID_VERSION_SEPARATOR
      + componentId.minor_version + COMPONENT_ID_VERSION_SEPARATOR
      + componentId.patch_version;
  }

  /**
   * Obtém o identificador do dado dentro de seu serviço de origem.
   * 
   * @return O identificador do dado dentro de seu serviço de origem.
   */
  public String getDataId() {
    return this.dataId;
  }

  public String getServiceInterfaceName() {
    return this.serviceInterfaceName;
  }

  public ComponentId getServiceComponentId() {
    return this.serviceComponentId;
  }

  public String getServiceFacetName() {
    return this.serviceFacetName;
  }

  public String getServiceFacetIOR() {
    return this.serviceFacetIOR;
  }

  /**
   * Obtém a chave do dado.
   * 
   * @return A chave do dado.
   */
  public byte[] getKey() {
    return this.key;
  }
}
