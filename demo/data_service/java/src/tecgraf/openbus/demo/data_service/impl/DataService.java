package tecgraf.openbus.demo.data_service.impl;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.jacorb.poa.POA;
import org.omg.PortableServer.Servant;
import org.omg.PortableServer.POAPackage.ServantNotActive;
import org.omg.PortableServer.POAPackage.WrongPolicy;

import scs.core.servant.ComponentContext;
import tecgraf.openbus.Openbus;
import tecgraf.openbus.data_service.DataDescription;
import tecgraf.openbus.data_service.DataView;
import tecgraf.openbus.data_service.DataViewHelper;
import tecgraf.openbus.data_service.IHDataServicePOA;
import tecgraf.openbus.data_service.InvalidDataKey;
import tecgraf.openbus.data_service.Metadata;
import tecgraf.openbus.data_service.OperationNotSupported;
import tecgraf.openbus.data_service.UnknownViews;
import tecgraf.openbus.demo.data_service.utils.DataKeyManager;
import tecgraf.openbus.demo.data_service.valuetypes.DataDescriptionImpl;
import tecgraf.openbus.demo.data_service.valuetypes.FileDataDescriptionImpl;
import tecgraf.openbus.file_system.FileDataDescriptionHelper;
import tecgraf.openbus.file_system.ILogFileViewHelper;

public class DataService extends IHDataServicePOA {

  private ComponentContext context;
  private List<File> roots;
  private POA poa;

  public DataService(ComponentContext context) {
    this.context = context;
    this.roots = new ArrayList<File>();
    this.poa = (POA) Openbus.getInstance().getRootPOA();
  }

  public void addRoots(byte[] rootKey) {
    DataKeyManager dataKey = new DataKeyManager(rootKey);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = dataKey.getKey();

    File file = new File(path);
    if (file.isDirectory())
      return; // Erro - não tem DataView

    roots.add(file);
  }

  @Override
  public void copyData(byte[] source_key, byte[] target_key)
    throws UnknownViews, InvalidDataKey, OperationNotSupported {
    throw new OperationNotSupported();
  }

  @Override
  public byte[] createData(byte[] parent_key, DataDescription prototype)
    throws InvalidDataKey, OperationNotSupported {
    DataKeyManager parentDataKey = new DataKeyManager(parent_key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String parentPath = parentDataKey.getKey();

    File file = new File(parentPath);
    if (!file.isDirectory())
      return null; // Erro - não da para criar

    String dataPath = parentPath + "/" + prototype.name;
    DataKeyManager dataKey = new DataKeyManager(dataPath);

    try {
      File newFile = new File(dataPath);
      newFile.createNewFile();
    }
    catch (IOException e) {
      return null; // Erro - não da para criar
    }

    return dataKey.getDataKey();
  }

  @Override
  public byte[] createDataFrom(byte[] parent_key, byte[] source_key)
    throws UnknownViews, InvalidDataKey, OperationNotSupported {
    throw new OperationNotSupported();
  }

  @Override
  public void deleteData(byte[] key) throws InvalidDataKey,
    OperationNotSupported {
    DataKeyManager parentDataKey = new DataKeyManager(key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = parentDataKey.getKey();

    File file = new File(path);
    if (!file.delete())
      return; // Erro - não conseguiu remover o arquivo
  }

  @Override
  public DataDescription[] getChildren(byte[] key) throws InvalidDataKey {
    DataKeyManager dataKey = new DataKeyManager(key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = dataKey.getKey();

    File file = new File(path);
    if (!file.isDirectory())
      return new DataDescriptionImpl[0]; // EROO

    File[] childrenFile = file.listFiles();
    if ((childrenFile == null) || (childrenFile.length == 0))
      return new DataDescriptionImpl[0]; // ERRO

    DataDescription[] childrenView = new DataDescription[childrenFile.length];
    for (int i = 0; i < childrenFile.length; i++) {
      File child = childrenFile[i];
      childrenView[i] = createDataDescription(child);
    }

    return childrenView;
  }

  @Override
  public DataDescription getDataDescription(byte[] key) throws InvalidDataKey {
    DataKeyManager dataKey = new DataKeyManager(key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = dataKey.getKey();

    File file = new File(path);
    if (file.isFile())
      return createDataDescription(file);
    else
      return null;
  }

  @Override
  public DataView getDataView(byte[] key, String viewInterface)
    throws InvalidDataKey {
    DataKeyManager dataKey = new DataKeyManager(key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = dataKey.getKey();

    File file = new File(path);
    if (file.isDirectory())
      return null; // Erro - não tem DataView

    String[] views = getViews(file);
    for (String view : views) {
      if (view.equals(viewInterface))
        return createDataView(key, file, viewInterface);
    }
    return null;

  }

  @Override
  public DataView[] getDataViewSeq(byte[][] keys, String viewInterface)
    throws InvalidDataKey {
    List<DataView> dataViewList = new ArrayList<DataView>();
    for (byte[] key : keys) {
      dataViewList.add(getDataView(key, viewInterface));
    }
    return (DataView[]) dataViewList.toArray();
  }

  @Override
  public DataDescription getParent(byte[] key) throws InvalidDataKey {
    DataKeyManager dataKey = new DataKeyManager(key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = dataKey.getKey();
    // String parentPath = path.substring(0, path.lastIndexOf(File.separator));
    // File parentFile = new File(parentPath);

    File file = new File(path);
    File parentFile = file.getParentFile();

    if (!parentFile.isDirectory())
      return null; // Erro - é uma pasta nao é um arquivo.

    return createDataDescription(parentFile);
  }

  @Override
  public DataDescription[] getRoots() {
    List<DataDescription> dataDesList = new ArrayList<DataDescription>();
    for (File file : this.roots) {
      dataDesList.add(createDataDescription(file));
    }
    DataDescription[] dataList =
      dataDesList.toArray(new DataDescription[dataDesList.size()]);
    return dataList;
  }

  @Override
  public void moveData(byte[] source_key, byte[] parent_destination_key)
    throws UnknownViews, InvalidDataKey, OperationNotSupported {
    throw new OperationNotSupported();
  }

  private DataDescription createDataDescription(File file) {
    int dotPos = file.getName().lastIndexOf(".");
    String[] view;
    if (dotPos > 0) {
      String extension = file.getName().substring(dotPos);
      if (extension.contains("log")) {
        view = new String[2];
        view[0] = FileDataDescriptionHelper.id();
        view[1] = ILogFileViewHelper.id();
      }
    }
    view = new String[1];
    view[0] = FileDataDescriptionHelper.id();

    // TODO Como fazer para pegar o Owner.
    return new FileDataDescriptionImpl(file.getName(), file.getPath(), view,
      new Metadata[0], (int) file.length(), file.getName(), file.isDirectory());

  }

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

  private DataView createDataView(byte[] key, File file, String viewInterface) {
    if (viewInterface.equals(ILogFileViewHelper.id())) {
      Servant fileView = new LogFileView(file.getPath(), key);
      try {
        Object obj = poa.servant_to_reference(fileView);
        return DataViewHelper.narrow(obj);
      }
      catch (WrongPolicy e) {
        e.printStackTrace();
      }
      catch (ServantNotActive e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
    }
    return null;
  }

  @Override
  public org.omg.CORBA.Object _get_component() {
    return context.getIComponent();
  }

}
