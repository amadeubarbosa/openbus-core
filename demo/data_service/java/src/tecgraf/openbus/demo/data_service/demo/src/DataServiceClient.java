package tecgraf.openbus.demo.data_service.demo.src;

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
import tecgraf.openbus.data_service.IHDataService;
import tecgraf.openbus.data_service.IHDataServiceHelper;
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
  public static void main(String[] args) throws UserException, OpenBusException {
    String userLogin = "tester";
    String userPassword = "tester";
    boolean result = true;

    Log.setLogsLevel(Level.WARNING);
    // Pega um login da linha de comando.
    if (args.length > 1) {
      userLogin = args[0];
      userPassword = args[1];
    }

    // Cria o Orb utilizando o JacORB
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

    // Acessa o OpenBus
    IRegistryService registryService = openbus.connect(userLogin, userPassword);

    ServiceOffer[] servicesOffers =
      registryService.find(new String[] { "IDataService" });
    ServiceOffer serviceOffer = servicesOffers[0];
    IComponent component = serviceOffer.member;

    Object dataServiceObject = component.getFacetByName("IDataService");
    IHDataService dataService = IHDataServiceHelper.narrow(dataServiceObject);

    // Inicio dos testes
    DataServiceTester tester =
      new DataServiceTester(dataService, openbus.getORB());
    DataKeyManager.setServerComponentId("IDataService");

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
      .println("\n\n<---- Removendo a árvore de arquivos de teste ---->");
    tester.removeFile();

    openbus.disconnect();

    if (result)
      System.out.println("\nFinalizado sem erros.");
    else
      System.out.println("\nFinalizado com erros.");

  }
}
