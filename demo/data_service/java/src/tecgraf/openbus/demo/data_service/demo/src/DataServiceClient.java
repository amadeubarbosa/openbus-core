package tecgraf.openbus.demo.data_service.demo.src;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import java.util.logging.Level;

import openbusidl.rs.IRegistryService;
import openbusidl.rs.ServiceOffer;

import org.omg.CORBA.Object;
import org.omg.CORBA.UserException;
import org.omg.CORBA_2_3.ORB;

import scs.core.IComponent;
import tecgraf.openbus.Openbus;
import tecgraf.openbus.data_service.DataDescriptionHelper;
import tecgraf.openbus.data_service.IHierarchicalDataService;
import tecgraf.openbus.data_service.IHierarchicalDataServiceHelper;
import tecgraf.openbus.data_service.UnstructuredDataHelper;
import tecgraf.openbus.demo.data_service.demo.util.DataServiceTester;
import tecgraf.openbus.demo.data_service.factorys.DataDescriptionDefaultFactory;
import tecgraf.openbus.demo.data_service.factorys.FileDataDescriptionDefaultFactory;
import tecgraf.openbus.demo.data_service.factorys.UnstructuredDataDefaultFactory;
import tecgraf.openbus.demo.data_service.utils.DataKeyManager;
import tecgraf.openbus.exception.OpenBusException;
import tecgraf.openbus.file_system.FileDataDescriptionHelper;
import tecgraf.openbus.util.Log;

public class DataServiceClient {
  public static void main(String[] args) throws UserException,
    OpenBusException, IOException {
    Log.setLogsLevel(Level.WARNING);
    boolean result = true;

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

    String userLogin = props.getProperty("login");
    String userPassword = props.getProperty("password");

    // Pega um login da linha de comando.
    if (args.length > 1) {
      userLogin = args[0];
      userPassword = args[1];
    }

    // Cria o Orb utilizando o JacORB
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

    // Acessa o OpenBus
    IRegistryService registryService = openbus.connect(userLogin, userPassword);

    String componentName = props.getProperty("component.name");
    String facetName = props.getProperty("component.facetName");

    ServiceOffer[] servicesOffers =
      registryService.find(new String[] { componentName });
    ServiceOffer serviceOffer = servicesOffers[0];
    IComponent component = serviceOffer.member;

    Object dataServiceObject = component.getFacetByName(facetName);
    IHierarchicalDataService dataService =
      IHierarchicalDataServiceHelper.narrow(dataServiceObject);

    // Inicio dos testes
    String demoPath = props.getProperty("demo.path");

    DataServiceTester tester =
      new DataServiceTester(dataService, openbus.getORB(), demoPath);
    DataKeyManager.setServerComponentId(componentName);

    System.out
      .println("<---- Criando a árvore de arquivos destinados para teste. ---->");
    tester.buildFiles();

    System.out
      .println("\n\n<---- Verificando alguns Files e imprimindo sua descrição ---->");
    result = result && tester.getSomeDataDescriptions();

    System.out
      .println("\n\n<---- Testando o LogFileView (interface remota) ---->");
    result = result && tester.getLogView();

    System.out
      .println("\n\n<---- Criando, verifica se foi criado e remove um arquivo ---->");
    result = result && tester.createAndRemoveData();

    System.out
      .println("\n\n<---- Verifica se o LogFileView está sendo desativado corretamente ---->");
    result = result && tester.testDeactivateLogInterface();

    System.out
      .println("\n\n<---- Removendo a árvore de arquivos de teste ---->");
    tester.removeFile();

    openbus.disconnect();

    if (result)
      System.out.println("\nFinalizado sem erros.");
    else
      System.out.println("\nFinalizado com erros.");

  }
}
