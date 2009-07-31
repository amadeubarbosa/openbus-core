package tecgraf.openbus.demo.data_service.impl;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.omg.PortableServer.POA;
import org.omg.PortableServer.Servant;
import org.omg.PortableServer.POAPackage.ServantNotActive;
import org.omg.PortableServer.POAPackage.WrongPolicy;

import scs.core.ComponentId;
import scs.core.servant.ComponentContext;
import tecgraf.openbus.Openbus;
import tecgraf.openbus.data_service.DataDescription;
import tecgraf.openbus.data_service.DataView;
import tecgraf.openbus.data_service.DataViewHelper;
import tecgraf.openbus.data_service.IHierarchicalDataServicePOA;
import tecgraf.openbus.data_service.InvalidDataKey;
import tecgraf.openbus.data_service.Metadata;
import tecgraf.openbus.data_service.ServiceFailure;
import tecgraf.openbus.data_service.UnknownViews;
import tecgraf.openbus.demo.data_service.utils.DataKey;
import tecgraf.openbus.demo.data_service.valuetypes.FileDataDescriptionImpl;
import tecgraf.openbus.file_system.FileDataDescription;
import tecgraf.openbus.file_system.FileDataDescriptionHelper;
import tecgraf.openbus.file_system.ILogFileViewHelper;

public class DataService extends IHierarchicalDataServicePOA {

  /** Campo de acesso ao componente (campo obrigat�rio). */
  private ComponentContext context;
  /** Armazena as raizes das �rvores de diret�rio. */
  private List<File> roots;
  private POA poa;
  private String facetName;

  /**
   * Construtor. Todas as classes que tiverem o comportamento de facetas devem
   * possuir um construtor com esta assinatura.
   * 
   * @param context
   */
  public DataService(ComponentContext context) {
    this.context = context;
    this.roots = new ArrayList<File>();
    this.poa = Openbus.getInstance().getRootPOA();
    this.facetName = "";
  }

  public void setFacetName(String facetName) {
    this.facetName = facetName;
  }

  public void addRoot(byte[] rootKey) throws InvalidDataKey {
    DataKey dataKey = new DataKey(rootKey);
    if (!verifyKey(dataKey))
      throw new InvalidDataKey();
    // TODO Testar se o usu�rio tem permiss�o de acesso.
    String path = dataKey.getDataId();

    File file = new File(path);
    roots.add(file);
  }

  @Override
  public byte[] createData(byte[] parentKey, DataDescription prototype)
    throws ServiceFailure, InvalidDataKey {
    DataKey parentDataKey = new DataKey(parentKey);
    if (!verifyKey(parentDataKey))
      throw new InvalidDataKey();
    // TODO Testar se o usu�rio tem permiss�o de acesso.
    String parentPath = parentDataKey.getDataId();

    File file = new File(parentPath);
    if (!file.isDirectory())
      throw new ServiceFailure("parentKey n�o � um diret�rio.");

    ComponentId componentId = context.getComponentId();
    String dataPath = parentPath + "/" + prototype.name;
    DataKey dataKey = new DataKey(dataPath, null, componentId, facetName, null);

    try {
      File newFile = new File(dataPath);
      System.out.println(dataPath);
      FileDataDescription fdDescription = (FileDataDescription) prototype;

      if (fdDescription.fIsContainer) {
        newFile.mkdir();
      }
      else {
        newFile.createNewFile();
      }

    }
    catch (IOException e) {
      throw new ServiceFailure();
    }

    return dataKey.getKey();
  }

  @Override
  public byte[] copyData(byte[] parentKey, byte[] sourceKey)
    throws ServiceFailure, UnknownViews, InvalidDataKey {
    throw new ServiceFailure("Not implemented");
  };

  @Override
  public void deleteData(byte[] key) throws ServiceFailure, InvalidDataKey {
    DataKey parentDataKey = new DataKey(key);
    if (!verifyKey(parentDataKey))
      throw new InvalidDataKey();
    // TODO Testar se o usu�rio tem permiss�o de acesso.
    String path = parentDataKey.getDataId();

    File file = new File(path);
    if (!deleteDir(file))
      throw new ServiceFailure("N�o � poss�vel remover este arquivo");
  }

  @Override
  public DataDescription[] getChildren(byte[] key) throws ServiceFailure,
    InvalidDataKey {
    DataKey dataKey = new DataKey(key);
    if (!verifyKey(dataKey))
      throw new InvalidDataKey();
    // TODO Testar se o usu�rio tem permiss�o de acesso.
    String path = dataKey.getDataId();

    File file = new File(path);
    if (!file.isDirectory())
      throw new ServiceFailure("parentKey n�o � um diret�rio.");

    File[] childrenFile = file.listFiles();
    if (childrenFile == null)
      throw new ServiceFailure("diret�rio n�o cont�m entradas");

    DataDescription[] childrenView = new DataDescription[childrenFile.length];
    for (int i = 0; i < childrenFile.length; i++) {
      File child = childrenFile[i];
      childrenView[i] = createDataDescription(child);
    }

    return childrenView;
  }

  @Override
  public DataDescription getDataDescription(byte[] key) throws ServiceFailure,
    InvalidDataKey {
    DataKey dataKey = new DataKey(key);
    if (!verifyKey(dataKey))
      throw new InvalidDataKey();
    // TODO Testar se o usu�rio tem permiss�o de acesso.
    String path = dataKey.getDataId();

    File file = new File(path);
    if (file.isFile())
      return createDataDescription(file);
    else
      return null;
  }

  @Override
  public DataView getDataView(byte[] key, String viewInterface)
    throws ServiceFailure, tecgraf.openbus.data_service.UnknownViewInterface,
    InvalidDataKey {
    DataKey dataKey = new DataKey(key);
    if (!verifyKey(dataKey))
      throw new InvalidDataKey();
    // TODO Testar se o usu�rio tem permiss�o de acesso.
    String path = dataKey.getDataId();

    File file = new File(path);
    if (file.isDirectory())
      throw new ServiceFailure("parentKey � um diret�rio.");

    String[] views = getViews(file);
    for (String view : views) {
      if (view.equals(viewInterface))
        return createDataView(key, file, viewInterface);
    }

    return null;
  }

  @Override
  public DataView[] getDataViewSeq(byte[][] keys, String viewInterface)
    throws ServiceFailure, tecgraf.openbus.data_service.UnknownViewInterface,
    InvalidDataKey {
    List<DataView> dataViewList = new ArrayList<DataView>();
    for (byte[] key : keys) {
      dataViewList.add(getDataView(key, viewInterface));
    }
    return (DataView[]) dataViewList.toArray();
  }

  @Override
  public DataDescription getParent(byte[] key) throws ServiceFailure,
    InvalidDataKey {
    DataKey dataKey = new DataKey(key);
    if (!verifyKey(dataKey))
      throw new InvalidDataKey();
    // TODO Testar se o usu�rio tem permiss�o de acesso.
    String path = dataKey.getDataId();

    File file = new File(path);
    File parentFile = file.getParentFile();

    if (!parentFile.isDirectory())
      throw new ServiceFailure();

    return createDataDescription(parentFile);

  }

  @Override
  public DataDescription[] getRoots() throws ServiceFailure {
    List<DataDescription> dataDesList = new ArrayList<DataDescription>();
    try {
      for (File file : this.roots) {
        dataDesList.add(createDataDescription(file));
      }
    }
    catch (InvalidDataKey e) {
      e.printStackTrace();
    }
    DataDescription[] dataList =
      dataDesList.toArray(new DataDescription[dataDesList.size()]);
    return dataList;
  }

  @Override
  public void moveData(byte[] key, byte[] newParentKey) throws ServiceFailure,
    UnknownViews, InvalidDataKey {
    throw new ServiceFailure("Not implemented");
  }

  @Override
  public void updateData(byte[] key, byte[] sourceKey) throws ServiceFailure,
    UnknownViews, InvalidDataKey {
    throw new ServiceFailure("Not implemented");
  }

  @Override
  public byte[] copyDataFrom(byte[] parentKey, byte[] sourceKey)
    throws ServiceFailure, UnknownViews, InvalidDataKey {
    throw new ServiceFailure("Not implemented");
  }

  @Override
  public void updateDataFrom(byte[] key, byte[] sourceKey)
    throws ServiceFailure, UnknownViews, InvalidDataKey {
    throw new ServiceFailure("Not implemented");
  }

  /**
   * Cria um DataDescription a partir de um arquivo
   * 
   * @param file O arquivo utilizado para criar o DataDescription
   * @return O DataDescription criado.
   * @throws InvalidDataKey
   */
  private DataDescription createDataDescription(File file)
    throws InvalidDataKey {
    int dotPos = file.getName().lastIndexOf(".");

    String[] view = new String[1];
    view[0] = FileDataDescriptionHelper.id();

    if (dotPos > 0) {
      String extension = file.getName().substring(dotPos);
      if (extension.contains("log")) {
        view = new String[2];
        view[0] = FileDataDescriptionHelper.id();
        view[1] = ILogFileViewHelper.id();
      }
    }

    // TODO Como fazer para pegar o Owner.
    ComponentId componentId = context.getComponentId();
    DataKey key =
      new DataKey(file.getPath(), null, componentId, facetName, null);
    return new FileDataDescriptionImpl(file.getName(), key.getKey(), view,
      new Metadata[0], (int) file.length(), file.getName(), file.isDirectory());
  }

  /**
   * Verifica se a {@code key} pertence ao DataService em quest�o.
   * 
   * @param key a chave que ser� verificada
   * @return {@code true} caso a chave perten�a ao servi�o. {@code false} caso
   *         contr�rio.
   */
  private boolean verifyKey(DataKey key) {
    ComponentId componentId = context.getComponentId();
    if ((key.getServiceComponentId() == null)
      || key.getServiceInterfaceName() == null)
      return false;
    if (key.getServiceComponentId().name.compareTo(componentId.name) != 0)
      return false;
    if (key.getServiceFacetName().compareTo(this.facetName) != 0)
      return false;

    return true;
  }

  /**
   * Retorna as vis�es de um dado a partir do arquivo.
   * 
   * @param file
   * @return As vis�es do arquivo.
   */
  private String[] getViews(File file) {
    int dotPos = file.getName().lastIndexOf(".");
    String extension = file.getName().substring(dotPos);
    String[] view;

    if (extension.contains("log")) {
      view = new String[2];
      view[0] = FileDataDescriptionHelper.id();
      view[1] = ILogFileViewHelper.id();
    }
    else {
      view = new String[1];
      view[0] = FileDataDescriptionHelper.id();
    }
    return view;
  }

  /**
   * Cria uma vis�o do dado a partir do arquivo e da vis�o desejada
   * 
   * @param key
   * @param file
   * @param viewInterface
   * @return A vis�o do dado.
   */
  private DataView createDataView(byte[] key, File file, String viewInterface) {
    if (viewInterface.equals(ILogFileViewHelper.id())) {
      Servant fileView = new LogFileView(file.getPath(), key);
      try {
        org.omg.CORBA.Object obj = poa.servant_to_reference(fileView);
        return DataViewHelper.narrow(obj);
      }
      catch (WrongPolicy e) {
        e.printStackTrace();
      }
      catch (ServantNotActive e) {
        e.printStackTrace();
      }
    }
    return null;
  }

  /**
   * Deleta um diret�rio. O diret�rio � deletado mesmo contendo arquivos.
   * 
   * @param dir
   * @return {@code true} caso o diret�rio tenha sido removido. {@code False}
   *         caso contr�rio.
   */
  public static boolean deleteDir(File dir) {
    if (dir.isDirectory()) {
      String[] children = dir.list();
      for (int i = 0; i < children.length; i++) {
        boolean success = deleteDir(new File(dir, children[i]));
        if (!success) {
          return false;
        }
      }
    }

    // The directory is now empty so delete it
    return dir.delete();
  }

  /**
   * M�todo obrigat�rio.
   * 
   * {@inheritDoc}
   */
  @Override
  public org.omg.CORBA.Object _get_component() {
    return context.getIComponent();
  }

}
