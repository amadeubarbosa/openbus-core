package tecgraf.openbus.demo.data_service.valuetypes;

import tecgraf.openbus.data_service.DataDescription;
import tecgraf.openbus.data_service.Metadata;

public class DataDescriptionImpl extends DataDescription {

  public DataDescriptionImpl() {
    this.key = new byte[0];
    this.name = "";
    this.views = new String[0];
    this.metadata = new Metadata[0];
  }

  public DataDescriptionImpl(String name, String[] views, Metadata[] metadata) {
    this.key = new byte[0];
    this.name = name;
    this.views = views;
    this.metadata = metadata;
  }
}
