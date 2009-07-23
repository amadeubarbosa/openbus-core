package tecgraf.openbus.demo.data_service.demo.util;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import org.omg.CORBA.ORB;

import tecgraf.openbus.data_service.DataDescription;
import tecgraf.openbus.data_service.DataView;
import tecgraf.openbus.data_service.IHDataService;
import tecgraf.openbus.data_service.InvalidDataKey;
import tecgraf.openbus.data_service.Metadata;
import tecgraf.openbus.data_service.OperationNotSupported;
import tecgraf.openbus.demo.data_service.valuetypes.DataDescriptionImpl;
import tecgraf.openbus.file_system.FileDataDescription;
import tecgraf.openbus.file_system.FileDataDescriptionHelper;
import tecgraf.openbus.file_system.ILogFileView;
import tecgraf.openbus.file_system.ILogFileViewHelper;

public class DataServiceTester {

  private IHDataService dataService;
  private ORB orb;
  public static final String rootPath = "DemoDataServiceTemp/";

  public DataServiceTester(IHDataService dataService, ORB orb) {
    this.dataService = dataService;
    this.orb = orb;
  }

  public void buildFiles() {
    try {
      File root = new File(rootPath);
      root.mkdirs();

      File project1 = new File(rootPath + "Project1");
      project1.mkdir();

      File project2 = new File(rootPath + "Project2");
      project2.mkdir();

      BufferedWriter file1 =
        new BufferedWriter(
          new FileWriter(rootPath + "Project1/file2.txt", true));
      file1
        .write("Aqui temos um contúdo muito interessante sobre o proejto1\n blablabla blablabla\n");
      file1.close();

      BufferedWriter logFile1 =
        new BufferedWriter(new FileWriter(rootPath + "Project2/file1.log"));
      logFile1
        .write("Teste\nProjeto1 \n[LOG] PENULTIMA LINHA\n[LOG] Ultima Linha\n");
      logFile1.close();
    }
    catch (IOException e) {
      e.printStackTrace();
    }
  }

  public boolean getSomeDataDescriptions() {

    DataDescription[] rootDescList = dataService.getRoots();
    if (rootDescList.length < 1)
      return false;

    DataDescription rootDesc = rootDescList[0];
    if (!(rootDesc instanceof FileDataDescription))
      return false;

    DataDescription projectDesc = null;
    DataDescription fileDesc = null;
    try {
      DataDescription[] children = dataService.getChildren(rootDesc.key);
      if (children.length < 1)
        return false;
      projectDesc = children[0];

      children = dataService.getChildren(projectDesc.key);
      if (children.length < 1)
        return false;
      fileDesc = children[0];

    }
    catch (InvalidDataKey e) {
      e.printStackTrace();
      return false;
    }

    printFileDataDescription((FileDataDescription) rootDesc);
    printFileDataDescription((FileDataDescription) projectDesc);
    printFileDataDescription((FileDataDescription) fileDesc);
    return true;
  }

  public boolean getLogView() {
    DataDescription[] rootDescList = dataService.getRoots();
    if (rootDescList.length < 1)
      return false;

    DataDescription rootDesc = rootDescList[0];
    DataDescription projectDesc = null;
    DataDescription logFileDesc = null;
    ILogFileView logFileView = null;
    try {
      DataDescription[] children = dataService.getChildren(rootDesc.key);
      if (children.length < 2)
        return false;
      projectDesc = children[1];

      children = dataService.getChildren(projectDesc.key);
      if (children.length < 1)
        return false;
      logFileDesc = children[0];
      DataView dataView =
        dataService.getDataView(logFileDesc.key, ILogFileViewHelper.id());
      logFileView = ILogFileViewHelper.narrow(dataView);

    }
    catch (InvalidDataKey e) {
      e.printStackTrace();
      return false;
    }
    String line = logFileView.getLastLine();

    printFileDataDescription((FileDataDescription) projectDesc);
    printFileDataDescription((FileDataDescription) logFileDesc);
    System.out.println("$ tail " + logFileDesc.name + "\n> " + line);
    return true;
  }

  public boolean createAndRemoveData() {
    DataDescription[] rootDescList = dataService.getRoots();
    if (rootDescList.length < 1)
      return false;

    DataDescription rootDesc = rootDescList[0];
    if (!(rootDesc instanceof FileDataDescription))
      return false;

    DataDescription projectDesc = null;
    try {
      DataDescription[] children = dataService.getChildren(rootDesc.key);
      if (children.length < 1)
        return false;
      projectDesc = children[0];

      String[] views = { FileDataDescriptionHelper.id() };
      DataDescription prototype =
        new DataDescriptionImpl("arquivoCriado.opt", views, new Metadata[0]);
      // Create newData
      byte[] newDatakey = dataService.createData(projectDesc.key, prototype);

      // Get newData
      FileDataDescription newDataDesc =
        (FileDataDescription) dataService.getDataDescription(newDatakey);
      printFileDataDescription(newDataDesc);

      // Delete newData
      dataService.deleteData(newDatakey);

    }
    catch (InvalidDataKey e) {
      e.printStackTrace();
      return false;
    }
    catch (OperationNotSupported e) {
      e.printStackTrace();
      return false;
    }

    return true;
  }

  public boolean removeFile() {
    boolean result = true;
    File logFile1 = new File(rootPath + "Project2/file1.log");
    File file1 = new File(rootPath + "Project1/file2.txt");
    File project2 = new File(rootPath + "Project2");
    File project1 = new File(rootPath + "Project1");
    File root = new File(rootPath);

    result = result && file1.delete();
    result = result && logFile1.delete();
    result = result && project2.delete();
    result = result && project1.delete();
    result = result && root.delete();

    return result;
  }

  private void printFileDataDescription(FileDataDescription data) {
    System.out.println("Elemento " + data.name);
    System.out.println("  Key = " + data.key);
    System.out.println("  Folder = " + data.fIsContainer);
    if (!data.fIsContainer)
      System.out.println("  Size = " + data.fSize + " bytes");
    System.out.println("  Views {");
    for (String view : data.views) {
      System.out.println("         " + view);
    }
    System.out.println("  }");

  }
}
