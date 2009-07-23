package tecgraf.openbus.demo.data_service.demo.src;



import java.util.Properties;
import java.util.logging.Level;

import openbusidl.rs.IRegistryService;
import openbusidl.rs.Property;
import openbusidl.rs.ServiceOffer;

import org.omg.CORBA.StringHolder;
import org.omg.CORBA_2_3.ORB;



import scs.core.ComponentId;
import scs.core.IComponent;
import scs.core.IComponentHelper;
import scs.core.servant.ComponentBuilder;
import scs.core.servant.ComponentContext;
import scs.core.servant.ExtendedFacetDescription;
import scs.core.servant.IComponentServant;
import scs.core.servant.IMetaInterfaceServant;
import tecgraf.openbus.Openbus;
import tecgraf.openbus.data_service.DataDescriptionHelper;
import tecgraf.openbus.data_service.UnstructuredDataHelper;
import tecgraf.openbus.demo.data_service.demo.util.DataServiceTester;
import tecgraf.openbus.demo.data_service.factorys.DataDescriptionDefaultFactory;
import tecgraf.openbus.demo.data_service.factorys.FileDataDescriptionDefaultFactory;
import tecgraf.openbus.demo.data_service.factorys.UnstructuredDataDefaultFactory;
import tecgraf.openbus.demo.data_service.impl.DataService;
import tecgraf.openbus.demo.data_service.utils.DataKeyManager;
import tecgraf.openbus.file_system.FileDataDescriptionHelper;
import tecgraf.openbus.util.Log;

public class DataServiceServer {
  public static void main(String[] args) throws Exception {

    Log.setLogsLevel(Level.WARNING);
    // Cria o ORB.
    Properties props = new Properties();
    props.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    props.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");

    Openbus openbus = Openbus.getInstance();
    openbus.resetAndInitialize(args, props, "localhost", 2089);
    ORB orb = (ORB) openbus.getORB();
    orb.register_value_factory(DataDescriptionHelper.id(),
      new DataDescriptionDefaultFactory());
    orb.register_value_factory(FileDataDescriptionHelper.id(),
      new FileDataDescriptionDefaultFactory());
    orb.register_value_factory(UnstructuredDataHelper.id(),
      new UnstructuredDataDefaultFactory());

    // Cria o componente.
    ComponentBuilder builder =
      new ComponentBuilder(openbus.getRootPOA(), openbus.getORB());
    ExtendedFacetDescription[] descriptions = new ExtendedFacetDescription[3];
    descriptions[0] =
      new ExtendedFacetDescription("IComponent", "IDL:scs/core/IComponent:1.0",
        IComponentServant.class.getCanonicalName());
    descriptions[1] =
      new ExtendedFacetDescription("IDataService", "IDL:idls/IDataService:1.0",
        DataService.class.getCanonicalName());
    descriptions[2] =
      new ExtendedFacetDescription("IMetaInterface",
        "IDL:scs/core/IMetaInterface:1.0", IMetaInterfaceServant.class
          .getCanonicalName());
    ComponentContext context =
      builder.newComponent(descriptions, null, new ComponentId("IDataService",
        (byte) 1, (byte) 0, (byte) 0, "Java"));

    DataKeyManager rootKey =
      new DataKeyManager("IDataService", DataServiceTester.rootPath);
    byte[] rootDataKey = rootKey.getDataKey();
    ((DataService) context.getFacets().get("IDataService"))
      .addRoots(rootDataKey);

    IRegistryService registryService = openbus.connect("tester", "tester");

    org.omg.CORBA.Object obj = context.getIComponent();
    IComponent component = IComponentHelper.narrow(obj);
    ServiceOffer serviceOffer = new ServiceOffer(new Property[0], component);
    StringHolder registrationId = new StringHolder();
    registryService.register(serviceOffer, registrationId);

    Runtime.getRuntime().addShutdownHook(new Thread() {
      @Override
      public void run() {
        Openbus openbus = Openbus.getInstance();
        openbus.disconnect();
        openbus.getORB().shutdown(true);
        openbus.getORB().destroy();
        System.out.println("Finalizando...");
        super.run();
      }
    });

    openbus.run();

  }

}
