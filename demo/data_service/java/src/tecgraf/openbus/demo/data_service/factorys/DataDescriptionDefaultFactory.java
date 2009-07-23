package tecgraf.openbus.demo.data_service.factorys;

import tecgraf.openbus.demo.data_service.valuetypes.DataDescriptionImpl;

/**
 * tecgraf/openbus/data_service/DataDescriptionDefaultFactory.java . Generated
 * by the IDL-to-Java compiler (portable), version "3.2" from data_service.idl
 * Terça-feira, 21 de Julho de 2009 16h07min57s BRT
 */

/**
 * \brief A descrição de um dado.
 * 
 * A descrição deve ter informações suficientes para que um determinado dado
 * seja identificado.
 */
public class DataDescriptionDefaultFactory implements
  org.omg.CORBA.portable.ValueFactory {

  public java.io.Serializable read_value(
    org.omg.CORBA_2_3.portable.InputStream is) {
    return is.read_value(new DataDescriptionImpl());
  }
}
