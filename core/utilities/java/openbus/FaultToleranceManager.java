package openbus;

import java.util.ArrayList;

import openbus.util.PropertiesLoaderImpl;

public class FaultToleranceManager {
	
	/**
	    * A lista de máquinas e portas que contem uma réplica rodando. 
	    */
		private ArrayList<Host> hosts;
		
		private static int NBR_SERVERS = Integer.valueOf(PropertiesLoaderImpl.getValor("numServers"));
		
		/**
		   * A máquina que contem a réplica que está sendo usada. 
		   */
		private Host hostInUse;
		
		private String strConfDir = "util\\FaultToleranceConfiguration.properties";
		
		private String serviceRef;
		
		private static FaultToleranceManager ftManager;
		
		//core/conf/FaultToleranceConfiguration.properties
		private FaultToleranceManager(String serviceRef) {
			this.serviceRef = serviceRef;
			this.hosts = new ArrayList<Host>();
			  setHosts();
		}
		
		private FaultToleranceManager(String serviceRef, String strDir) {
			this.serviceRef = serviceRef;
			this.strConfDir = strDir;
			this.hosts = new ArrayList<Host>();
			  setHosts();
		}
		
		public static FaultToleranceManager getInstance(String serviceRef){
			if (ftManager == null)
				ftManager = new FaultToleranceManager(serviceRef);
			return ftManager;
		}
		
		public static FaultToleranceManager getInstance(String serviceRef, String strDir){
			if (ftManager == null)
				ftManager = new FaultToleranceManager(serviceRef, strDir);
			return ftManager;
		}
		
		
		/**
		   * Popula a lista de hosts que contem as réplicas do Serviço Tolerante a Falhas.
		   * 
		   */
		  private void setHosts() {

			if(this.hosts==null)
				this.hosts = new ArrayList<Host>();

			for (int i = 1; i <= NBR_SERVERS; i++) {
				String[] hostStr = (PropertiesLoaderImpl.getValor(serviceRef + "HostAdd-" + i)).split(":");
				String name =  hostStr[0];
				int port = Integer.valueOf(hostStr[1]);
				this.hosts.add( new Host(name, port) );
			}
			
			//this.hosts.add(new Host("localhost", 2089));
			//this.hosts.add(new Host("127.0.0.1", 2090));

			
			this.hostInUse = this.hosts.get(0);
		}
		  
		  public ArrayList<Host> getHosts() {
				return hosts;
			}


			public void setHosts(ArrayList<Host> hosts) {
				this.hosts = hosts;
			}


			public Host getHostInUse() {
				return hostInUse;
			}


			public void setHostInUse(Host hostInUse) {
				this.hostInUse = hostInUse;
			}
			
			/**
			   * No caso de uma falha de réplica, este método deve ser chamado para atualizar a máquina a ser 
			   * obtida uma réplica.
			   */
			  public void updateHostInUse(){
			  		int indexCurr = this.hosts.indexOf(this.hostInUse);
			      	//Se a maquina em uso eh a ultima da lista, eu pego a primeira
			      	if(indexCurr==this.hosts.size()-1){
			      		this.hostInUse = this.hosts.get(0);
			      	}else{
			      		for (Host host : this.hosts) {
			      			if(indexCurr< this.hosts.indexOf(host)){
			      				//se eu estou na proxima maquina da list
			      				this.hostInUse = host;
			      				break;
			      			}
			      		}
			      	}
			  }  
		
		

}
