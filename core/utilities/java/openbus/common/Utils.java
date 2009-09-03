/*
 * $Id$
 */
package openbus.common;

import java.security.GeneralSecurityException;
import java.security.PrivateKey;
import java.security.cert.Certificate;

import openbus.ORBWrapper;
import openbus.RegistryServiceWrapper;
import openbus.common.exception.ACSUnavailableException;
import openbus.exception.CORBAException;
import openbusidl.acs.IAccessControlService;
import openbusidl.acs.IAccessControlServiceHelper;
import openbusidl.ds.IDataService;
import openbusidl.ds.IDataServiceHelper;
import openbusidl.rs.Property;
import openbusidl.rs.ServiceOffer;
import openbusidl.ss.ISessionService;
import openbusidl.ss.ISessionServiceHelper;

import org.omg.CORBA.Object;
import org.omg.CORBA.SystemException;

import scs.core.ComponentId;
import scs.core.IComponent;

/**
 * M�todos utilit�rios para uso do OpenBus.
 * 
 * @author Tecgraf/PUC-Rio
 */
public final class Utils {
  /**
   * Representa a interface do servi�o de controle de acesso.
   */
  public static final String ACCESS_CONTROL_SERVICE_INTERFACE =
    "IDL:openbusidl/acs/IAccessControlService:1.0";
  /**
   * Representa a interface do servi�o de sess�o.
   */
  public static final String SESSION_SERVICE_INTERFACE =
    "IDL:openbusidl/ss/ISessionService:1.0";
  /**
   * O nome da faceta do Servi�o de Sess�o.
   */
  private static final String SESSION_SERVICE_FACET_NAME = "sessionService";
  /**
   * O nome da propriedade que representa as facetas de um membro registrado.
   */
  private static final String FACETS_PROPERTY_NAME = "facets";
  /**
   * Representa a interface do servi�o de Dddos.
   */
  public static final String DATA_SERVICE_INTERFACE =
    "IDL:openbusidl/ds/IDataService:1.0";
  /**
   * Nome da propriedade que indica o identificador de um componente.
   */
  public static final String COMPONENT_ID_PROPERTY_NAME = "component_id";

  /**
   * Obt�m o servi�o de controle de acesso.
   * 
   * @param orb O orb utilizado para obter o servi�o.
   * @param host A m�quina onde o servi�o est� localizado.
   * @param port A porta onde o servi�o est� dispon�vel.
   * 
   * @return O servi�o de controle de acesso.
   * 
   * @throws ACSUnavailableException Caso o servi�o n�o seja encontrado.
   * @throws CORBAException Caso ocorra alguma exce��o na infra-estrutura CORBA.
   */
  public static IAccessControlService fetchAccessControlService(ORBWrapper orb,
    String host, int port) throws ACSUnavailableException, CORBAException {
    try {
      org.omg.CORBA.Object obj =
        orb.getORB().string_to_object(
          "corbaloc::1.0@" + host + ":" + port + "/ACS");
      if ((obj == null) || (obj._non_existent())) {
        throw new ACSUnavailableException();
      }
      return IAccessControlServiceHelper.narrow(obj);
    }
    catch (SystemException e) {
      e.printStackTrace();
      throw new CORBAException(e);
    }
  }

  /**
   * Gera a resposta para o desafio gerado pelo servi�o de controle de acesso.
   * 
   * @param challenge O desafio.
   * @param privateKey A chave privada de quem est� respondendo ao desafio.
   * @param acsCertificate O certificado do servi�o de controle de acesso
   * 
   * @return A resposta para o desafio.
   * 
   * @throws GeneralSecurityException Caso ocorra algum problema durante a
   *         opera��o.
   */
  public static byte[] generateAnswer(byte[] challenge, PrivateKey privateKey,
    Certificate acsCertificate) throws GeneralSecurityException {
    byte[] plainChallenge = CryptoUtils.decrypt(privateKey, challenge);
    return CryptoUtils.encrypt(acsCertificate, plainChallenge);
  }

  /**
   * Obt�m o servi�o de sess�o.
   * 
   * @param registryService O servi�o de registro.
   * 
   * @return O servi�o de sess�o, ou {@code null}, caso n�o seja encontrado.
   * 
   * @throws CORBAException Caso ocorra alguma exce��o na infra-estrutura CORBA.
   */
  public static ISessionService getSessionService(
    RegistryServiceWrapper registryService) throws CORBAException {
    Property[] properties = new openbusidl.rs.Property[1];
    properties[0] =
      new Property(FACETS_PROPERTY_NAME,
        new String[] { SESSION_SERVICE_FACET_NAME });
    try {
      ServiceOffer[] offers = registryService.find(properties);
      if (offers.length == 1) {
        IComponent component = offers[0].member;
        Object facet = component.getFacet(SESSION_SERVICE_INTERFACE);
        if (facet == null) {
          return null;
        }
        return ISessionServiceHelper.narrow(facet);
      }
      return null;
    }
    catch (SystemException e) {
      throw new CORBAException(e);
    }
  }

  /**
   * Obt�m um servi�o de dados.
   * 
   * @param registryService O servi�o de registro.
   * @param dataServiceId O identificador do Servi�o de Dados.
   * 
   * @return O servi�o de dados, ou {@code null}, caso n�o seja encontrado.
   * 
   * @throws CORBAException Caso ocorra alguma exce��o na infra-estrutura CORBA.
   */
  public static IDataService getDataService(
    RegistryServiceWrapper registryService, ComponentId dataServiceId)
    throws CORBAException {
    Property[] properties = new Property[1];
    properties[0] =
      new Property(COMPONENT_ID_PROPERTY_NAME,
        new String[] { dataServiceId.name + ":" + dataServiceId.major_version
          + dataServiceId.minor_version + dataServiceId.patch_version });
    try {
      ServiceOffer[] offers = registryService.find(properties);
      if (offers.length == 1) {
        IComponent dataServiceComponent = offers[0].member;
        Object dataServiceFacet =
          dataServiceComponent.getFacet(DATA_SERVICE_INTERFACE);
        if (dataServiceFacet == null) {
          return null;
        }
        return IDataServiceHelper.narrow(dataServiceFacet);
      }
      return null;
    }
    catch (SystemException e) {
      throw new CORBAException(e);
    }
  }
}