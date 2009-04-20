/*
 * $Id$
 */
package openbus;

import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.util.ArrayList;

import openbus.common.exception.ACSUnavailableException;
import openbus.exception.CORBAException;
import openbus.exception.InvalidCredentialException;
import openbus.exception.PKIException;
import openbusidl.Credential;
import openbusidl.acs.IAccessControlService;
import openbusidl.acs.IAccessControlServiceHelper;

import org.omg.CORBA.COMM_FAILURE;
import org.omg.CORBA.SystemException;
import org.omg.CORBA.TRANSIENT;

/**
 * Encapsula o Serviço de Controle de Acesso Tolerante a Falhas.
 * 
 * @author Tecgraf/PUC-Rio
 */
public final class FTAccessControlServiceWrapper extends AccessControlServiceWrapper{
	
	private ORBWrapper orb;
	
	private FaultToleranceManager ftManager;
  /**
   * Cria um objeto que encapsula o Serviço de Controle de Acesso Tolerante a Falhas.
   * 
   * @param orb O orb utilizado para obter o serviço.
   * 
   * @throws ACSUnavailableException Caso o serviço não seja encontrado.
   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
   */
  public FTAccessControlServiceWrapper(ORBWrapper orb)
    throws ACSUnavailableException, CORBAException {
	  super();
	  this.orb = orb;
	  this.ftManager = FaultToleranceManager.getInstance("acs");
	
      this.acs = fetchNewAccessControlService();
      this.rs = new FTRegistryServiceWrapper(orb);
  }

 
/**
   * Autentica uma entidade a partir de um nome de usuário e senha.
   * 
   * @param name O nome do usuário.
   * @param password A senha do usuário.
   * 
   * @return {@code true} caso a entidade seja autenticada, ou {@code false},
   *         caso contrário.
   * 
   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
   * @throws ACSUnavailableException 
   */
  public boolean loginByPassword(String name, String password)
    throws CORBAException, ACSUnavailableException {
	  checkAcessControlService();
	  return super.loginByPassword(name, password);
  }

  

/**
   * Autentica uma entidade a partir de um certificado digital.
   * 
   * @param name O nome da entidade.
   * @param privateKey A chave privada da entidade.
   * @param acsCertificate O certificado digital do Serviço de Controle de
   *        Acesso.
   * 
   * @return {@code true} caso a entidade seja autenticada, ou {@code false},
   *         caso contrário.
   * 
   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
   * @throws PKIException
 * @throws ACSUnavailableException 
   */
  public boolean loginByCertificate(String name, RSAPrivateKey privateKey,
    X509Certificate acsCertificate) throws CORBAException, PKIException, ACSUnavailableException {
	  checkAcessControlService();
	  return super.loginByCertificate(name, privateKey, acsCertificate);
  }

  /**
   * Autentica uma entidade a partir de uma credencial.
   * 
   * @param credential A credencial.
   * 
   * @return {@code true} caso a entidade seja autenticada, ou {@code false},
   *         caso contrário.
   * 
   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
 * @throws ACSUnavailableException 
   */
  public boolean loginByCredential(Credential credential) throws CORBAException, ACSUnavailableException {
	  checkAcessControlService();
	  return super.loginByCredential(credential);
  }

  /**
   * Desconecta a entidade em relação ao Serviço.
   * 
   * @return {@code true}, caso a entidade seja desconectada, ou {@code false},
   *         caso contrário.
   * 
   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
 * @throws ACSUnavailableException 
   */
  public boolean logout() throws CORBAException, ACSUnavailableException {
	  checkAcessControlService();
	  return super.logout();
  }

  /**
   * Obtém o Serviço de Registro.
   * 
   * @return O Serviço de Registro, ou {@code null}, caso o Serviço não esteja
   *         disponível.
   * 
   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
   * @throws InvalidCredentialException Indica que a credencial da entidade não
   *         é mais válida.
 * @throws ACSUnavailableException 
   */
  public FTRegistryServiceWrapper getRegistryService() throws CORBAException,
    InvalidCredentialException, ACSUnavailableException {
	  checkAcessControlService();
	  return (FTRegistryServiceWrapper)super.getRegistryService();
  }

  /**
   * Verifica se uma determinada credencial é válida.
   * 
   * @param credential A credencial.
   * 
   * @return {@code true} caso a credencial seja válida, ou {@code false}, caso
   *         contrário.
   * 
   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
 * @throws ACSUnavailableException 
   */
  public boolean isValid(Credential credential) throws CORBAException, ACSUnavailableException {
	  checkAcessControlService();
	  return super.isValid(credential);
  }

  

  /**
   * Obtém uma réplica do serviço de controle de acesso tolerante a falhas.
   * 
   * @param orb O orb utilizado para obter o serviço.
   * 
   * @return Uma réplica do serviço de controle de acesso tolerante a falhas.
   * 
   * @throws ACSUnavailableException Caso o serviço não seja encontrado.
   * @throws CORBAException Caso ocorra alguma exceção na infra-estrutura CORBA.
   */
  private IAccessControlService fetchNewAccessControlService() 
  			throws ACSUnavailableException, CORBAException 
  {
    try {
    	
    	org.omg.CORBA.Object obj  = 
    		fetchNewAccessControlServiceObj(ftManager.getHostInUse().getHostName(), ftManager.getHostInUse().getHostPort());
    	
    	int trials = 0;
    	//tenta pegar referencia em todas as maquinas até que encontre ou tenha testado todas
    	while((obj == null)  && (trials < ftManager.getHosts().size())) {
    		ftManager.updateHostInUse();
    		obj = fetchNewAccessControlServiceObj(ftManager.getHostInUse().getHostName(), ftManager.getHostInUse().getHostPort());
    		trials++;
    	}
    	//se testou todas as máquinas e nao encontrou, retorna uma exceção
    	if((obj == null) && (trials >= ftManager.getHosts().size())){
    		throw new ACSUnavailableException();
    	}
    	//retorna a réplica encontrada
        return IAccessControlServiceHelper.narrow(obj);
    }
    catch (SystemException e) {
      e.printStackTrace();
      throw new CORBAException(e);
    }
  }
  
  private org.omg.CORBA.Object fetchNewAccessControlServiceObj(String host, Integer port) 
	throws ACSUnavailableException, CORBAException 
	{
		try {
			org.omg.CORBA.Object obj  = orb.getORB().string_to_object(
			      "corbaloc::1.0@" + host + ":" + port + "/ACS");
			
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
  
  
  /**
   * Verifica se a réplica do serviço de controle de acesso tolerante a falhas que está sendo usada
   * está em estado de falha. Caso afirmativo, procura por outra réplica que esteja funcionando.
   * 
   * @throws CORBAException 
   * @throws ACSUnavailableException 
   * 
   */
  private void checkAcessControlService() throws CORBAException, ACSUnavailableException {
	   boolean replicaIsAlive = true;
		try {
			
			replicaIsAlive = this.acs.isAlive();
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
	    	this.acs = fetchNewAccessControlService();
	    	
	    	
	    }
  }
  
  
  
}
