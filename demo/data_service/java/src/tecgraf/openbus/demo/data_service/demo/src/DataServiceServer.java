package tecgraf.openbus.demo.data_service.demo.src;

import java.io.InputStream;
import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
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
import tecgraf.openbus.demo.data_service.factorys.DataDescriptionDefaultFactory;
import tecgraf.openbus.demo.data_service.factorys.FileDataDescriptionDefaultFactory;
import tecgraf.openbus.demo.data_service.factorys.UnstructuredDataDefaultFactory;
import tecgraf.openbus.demo.data_service.impl.DataService;
import tecgraf.openbus.demo.data_service.utils.DataKey;
import tecgraf.openbus.file_system.FileDataDescriptionHelper;
import tecgraf.openbus.util.CryptoUtils;
import tecgraf.openbus.util.Log;

public class DataServiceServer {

  public static void main(String[] args) throws Exception {
    Log.setLogsLevel(Level.WARNING);
    Properties props = new Properties();
    InputStream in =
      DataServiceServer.class.getResourceAsStream("/DataService.properties");
    try {
      props.load(in);
    }
    finally {
      in.close();
    }

    String host = props.getProperty("host.name");
    String portString = props.getProperty("host.port");
    int port = Integer.valueOf(portString);

    String entityName = props.getProperty("entity.name");
    String privateKeyFile = props.getProperty("private.key");
    String acsCertificateFile = props.getProperty("acs.certificate");

    // Cria o ORB.
    Properties orbProps = new Properties();
    orbProps.setProperty("org.omg.CORBA.ORBClass", "org.jacorb.orb.ORB");
    orbProps.setProperty("org.omg.CORBA.ORBSingletonClass",
      "org.jacorb.orb.ORBSingleton");

    Openbus openbus = Openbus.getInstance();
    openbus.resetAndInitialize(args, orbProps, host, port);
    ORB orb = (ORB) openbus.getORB();
    orb.register_value_factory(DataDescriptionHelper.id(),
      new DataDescriptionDefaultFactory());
    orb.register_value_factory(FileDataDescriptionHelper.id(),
      new FileDataDescriptionDefaultFactory());
    orb.register_value_factory(UnstructuredDataHelper.id(),
      new UnstructuredDataDefaultFactory());

    String componentName = props.getProperty("component.name");
    String facetName = props.getProperty("component.facetName");

    // Cria o componente.
    ComponentBuilder builder =
      new ComponentBuilder(openbus.getRootPOA(), openbus.getORB());
    ExtendedFacetDescription[] descriptions = new ExtendedFacetDescription[3];
    descriptions[0] =
      new ExtendedFacetDescription("IComponent", "IDL:scs/core/IComponent:1.0",
        IComponentServant.class.getCanonicalName());
    descriptions[1] =
      new ExtendedFacetDescription(facetName, "IDL:idls/IDataService:1.0",
        DataService.class.getCanonicalName());
    descriptions[2] =
      new ExtendedFacetDescription("IMetaInterface",
        "IDL:scs/core/IMetaInterface:1.0", IMetaInterfaceServant.class
          .getCanonicalName());
    ComponentId componentId =
      new ComponentId(componentName, (byte) 1, (byte) 0, (byte) 0, "Java");
    ComponentContext context =
      builder.newComponent(descriptions, null, componentId);

    String demoPath = props.getProperty("demo.path");

    DataKey rootKey = new DataKey(demoPath, null, componentId, facetName, null);
    byte[] rootDataKey = rootKey.getKey();
    ((DataService) context.getFacets().get(facetName)).setComponent(
      componentId, facetName);
    ((DataService) context.getFacets().get(facetName)).addRoots(rootDataKey);

    // Loga no Openbus por certificado
    RSAPrivateKey privateKey = CryptoUtils.readPrivateKey(privateKeyFile);
    X509Certificate acsCertificate =
      CryptoUtils.readCertificate(acsCertificateFile);

    IRegistryService registryService =
      openbus.connect(entityName, privateKey, acsCertificate);

    // Adiciona o componente no serviço de registro
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
