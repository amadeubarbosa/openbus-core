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
import tecgraf.openbus.data_service.IHierarchicalDataServicePOA;
import tecgraf.openbus.data_service.InvalidDataKey;
import tecgraf.openbus.data_service.Metadata;
import tecgraf.openbus.data_service.ServiceFailure;
import tecgraf.openbus.data_service.UnknownViews;
import tecgraf.openbus.demo.data_service.utils.DataKeyManager;
import tecgraf.openbus.demo.data_service.valuetypes.DataDescriptionImpl;
import tecgraf.openbus.demo.data_service.valuetypes.FileDataDescriptionImpl;
import tecgraf.openbus.file_system.FileDataDescriptionHelper;
import tecgraf.openbus.file_system.ILogFileViewHelper;

public class DataService extends IHierarchicalDataServicePOA {

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

    roots.add(file);
  }

  @Override
  public byte[] createData(byte[] parentKey, DataDescription prototype)
    throws ServiceFailure, InvalidDataKey {
    DataKeyManager parentDataKey = new DataKeyManager(parentKey);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String parentPath = parentDataKey.getKey();

    File file = new File(parentPath);
    if (!file.isDirectory())
      throw new ServiceFailure("parentKey não é um diretório.");

    String dataPath = parentPath + "/" + prototype.name;
    DataKeyManager dataKey = new DataKeyManager(dataPath);

    try {
      File newFile = new File(dataPath);
      newFile.createNewFile();
    }
    catch (IOException e) {
      throw new ServiceFailure();
    }

    return dataKey.getDataKey();
  }

  @Override
  public byte[] copyData(byte[] parentKey, byte[] sourceKey)
    throws ServiceFailure, UnknownViews, InvalidDataKey {
    throw new ServiceFailure("Not implemented");
  };

  @Override
  public void deleteData(byte[] key) throws ServiceFailure, InvalidDataKey {
    DataKeyManager parentDataKey = new DataKeyManager(key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = parentDataKey.getKey();

    File file = new File(path);
    if (!file.delete())
      throw new ServiceFailure("Não é possível remover este arquivo");
  }

  @Override
  public DataDescription[] getChildren(byte[] key) throws ServiceFailure,
    InvalidDataKey {
    DataKeyManager dataKey = new DataKeyManager(key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = dataKey.getKey();

    File file = new File(path);
    if (!file.isDirectory())
      throw new ServiceFailure("parentKey não é um diretório.");

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
  public DataDescription getDataDescription(byte[] key) throws ServiceFailure,
    InvalidDataKey {
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
    throws ServiceFailure, tecgraf.openbus.data_service.UnknownViewInterface,
    InvalidDataKey {
    DataKeyManager dataKey = new DataKeyManager(key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = dataKey.getKey();

    File file = new File(path);
    if (file.isDirectory())
      throw new ServiceFailure("parentKey é um diretório.");

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
    DataKeyManager dataKey = new DataKeyManager(key);
    // TODO Verificar se o DataKey está no mesmo componente com a mesma IDL ---
    // throw InvalidDataKey().
    // TODO Testar se o usuário tem permissão de acesso.
    String path = dataKey.getKey();

    File file = new File(path);
    File parentFile = file.getParentFile();

    if (!parentFile.isDirectory())
      throw new ServiceFailure();

    return createDataDescription(parentFile);
  }

  @Override
  public DataDescription[] getRoots() throws ServiceFailure {
    List<DataDescription> dataDesList = new ArrayList<DataDescription>();
    for (File file : this.roots) {
      dataDesList.add(createDataDescription(file));
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

  @Override
  public org.omg.CORBA.Object _get_component() {
    return context.getIComponent();
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
        e.printStackTrace();
      }
    }
    return null;
  }

}
