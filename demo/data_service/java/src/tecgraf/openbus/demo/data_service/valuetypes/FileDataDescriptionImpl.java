package tecgraf.openbus.demo.data_service.valuetypes;

import tecgraf.openbus.data_service.Metadata;
import tecgraf.openbus.demo.data_service.utils.DataKeyManager;
import tecgraf.openbus.file_system.FileDataDescription;

public class FileDataDescriptionImpl extends FileDataDescription {

  public FileDataDescriptionImpl() {
    this.name = "";
    this.views = new String[0];
    this.metadata = new Metadata[0];
    this.fSize = -1;
    this.fOwner = "";
    this.fIsContainer = false;
  }

  public FileDataDescriptionImpl(String name, String path, String[] views,
    Metadata[] metadata, int size, String owner, boolean isContainer) {
    this.name = name;
    this.key = new DataKeyManager(path).getDataKey();
    this.views = views;
    this.metadata = metadata;
    this.fSize = size;
    this.fOwner = owner;
    this.fIsContainer = isContainer;
  }

}
