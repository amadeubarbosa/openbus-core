package openbus;

import openbus.common.exception.RegistryUnavailableException;
import openbus.exception.CORBAException;
import openbusidl.rs.IRegistryService;
import openbusidl.rs.IRegistryServiceHelper;
import openbusidl.rs.Property;
import openbusidl.rs.ServiceOffer;

import org.omg.CORBA.COMM_FAILURE;
import org.omg.CORBA.SystemException;
import org.omg.CORBA.TRANSIENT;

public class FTRegistryServiceWrapper extends RegistryServiceWrapper {
	
	private ORBWrapper orb;
	
	private FaultToleranceManager ftManager;

	public FTRegistryServiceWrapper(ORBWrapper orb) {
		super();
		this.orb = orb;
		this.ftManager = FaultToleranceManager.getInstance("rs");
	}
	
	
	/**
	   * Registra uma oferta de serviço.
	   * 
	   * @param offer A oferta.
	   * 
	   * @return O identificador do registro da oferta.
	   * 
	   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
	 * @throws RegistryUnavailableException 
	   */
	  public String register(ServiceOffer offer) throws CORBAException, RegistryUnavailableException {
	     checkRegistryService();
	     return super.register(offer);
	  }

	  /**
	   * Retira o registro de uma oferta de serviço.
	   * 
	   * @param offerIdentifier O identificador do registro da oferta.
	   * 
	   * @return {@code true} caso o registro seja retirado, ou {@code false}, caso
	   *         contrário.
	   * 
	   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
	 * @throws RegistryUnavailableException 
	   */
	  public boolean unregister(String offerIdentifier) throws CORBAException, RegistryUnavailableException {
		 checkRegistryService();
		 return super.unregister(offerIdentifier);
	   
	  }

	  /**
	   * Atualiza as propriedades de uma oferta de serviço.
	   * 
	   * @param offerIdentifier O identificador do registro da oferta.
	   * @param newProperties As novas propriedades da oferta.
	   * 
	   * @return {@code true} caso o registro seja atualizado, ou {@code false},
	   *         caso contrário.
	   * 
	   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
	 * @throws RegistryUnavailableException 
	   */
	  public boolean update(String offerIdentifier, Property[] newProperties)
	    throws CORBAException, RegistryUnavailableException {
		  checkRegistryService();
			 return super.update(offerIdentifier, newProperties);
	  }

	  /**
	   * Realiza uma busca por ofertas de serviço através de determinados critérios.
	   * 
	   * @param criteria Os critérios.
	   * 
	   * @return As ofertas de serviço encontradas.
	   * 
	   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
	 * @throws RegistryUnavailableException 
	   */
	  public ServiceOffer[] find(Property[] criteria) throws CORBAException, RegistryUnavailableException {
		  checkRegistryService();
		  return super.find(criteria);
	  }
	  
	  
	  /**
	   * Verifica se a réplica do serviço de controle de acesso tolerante a falhas que está sendo usada
	   * está em estado de falha. Caso afirmativo, procura por outra réplica que esteja funcionando.
	   * 
	   * @throws CORBAException 
	   * @throws RegistryUnavailableException 
	   * 
	   */
	  private void checkRegistryService() throws CORBAException, RegistryUnavailableException {
		   boolean replicaIsAlive = true;
			try {
				
				replicaIsAlive = this.rs.isAlive();
				if (replicaIsAlive) return;
				
		    }catch (COMM_FAILURE ce){
		    	
		    	replicaIsAlive = false;
		    	
		    }catch (SystemException e) {
		    	
		    	e.printStackTrace();
		    	throw new CORBAException(e);
		    	
			}
		    
		    if (!replicaIsAlive){
		    	//procura por outra réplica que esteja funcionando.
		    	ftManager.updateHostInUse();
		    	this.rs = fetchRegistryService();
		    	
		    	
		    }
	  }
	  
	  
	  /**
	   * Obtém uma réplica do serviço de registro tolerante a falhas.
	   * 
	   * @param orb O orb utilizado para obter o serviço.
	   * 
	   * @return Uma réplica do serviço de registro tolerante a falhas.
	   * 
	   * @throws RegistryUnavailableException Caso o serviço não seja encontrado.
	   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
	   */
	  private IRegistryService fetchRegistryService() 
	  			throws RegistryUnavailableException, CORBAException 
	  {
	    try {
	    	
	    	org.omg.CORBA.Object obj  = 
	    		fetchNewRegistryServiceObj(ftManager.getHostInUse().getHostName(), ftManager.getHostInUse().getHostPort());
	    	
	    	int trials = 0;
	    	//tenta pegar referencia em todas as maquinas até que encontre ou tenha testado todas
	    	while((obj == null)  && (trials < ftManager.getHosts().size())) {
	    		ftManager.updateHostInUse();
	    		obj = fetchNewRegistryServiceObj(ftManager.getHostInUse().getHostName(), ftManager.getHostInUse().getHostPort());
	    		trials++;
	    	}
	    	//se testou todas as máquinas e nao encontrou, retorna uma exceção
	    	if((obj == null) && (trials >= ftManager.getHosts().size())){
	    		throw new RegistryUnavailableException();
	    	}
	    	//retorna a réplica encontrada
	        return IRegistryServiceHelper.narrow(obj);
	    }
	    catch (SystemException e) {
	      e.printStackTrace();
	      throw new CORBAException(e);
	    }
	  }
	  
	  private org.omg.CORBA.Object fetchNewRegistryServiceObj(String host, Integer port) 
		throws RegistryUnavailableException, CORBAException 
		{
			try {
				org.omg.CORBA.Object obj  = orb.getORB().string_to_object(
				      "corbaloc::1.0@" + host + ":" + port + "/RS");
				
				if(obj==null)  return null;
				
				if(obj._non_existent())  return null;
				
				return obj;
			}
			catch (TRANSIENT te) {
				return null;
			}
			catch (SystemException e) {
				return null;
			}
		}
	
	

}
