/*
 * $Id$
 */
package openbus.exception;

import openbus.common.exception.OpenBusException;

import org.omg.CORBA.SystemException;

/**
 * Representa uma exce��o gerada pelo <i>runtime</i> de CORBA.
 * 
 * @author Tecgraf/PUC-Rio
 */
public final class CORBAException extends OpenBusException {
  /**
   * Cria a exce��o com uma causa associada.
   * 
   * @param cause A causa.
   */
  public CORBAException(SystemException cause) {
    super(cause);
  }
}