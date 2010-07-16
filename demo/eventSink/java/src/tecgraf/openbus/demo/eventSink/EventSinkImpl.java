package tecgraf.openbus.demo.eventSink;

import openbusidl.ss.SessionEvent;
import openbusidl.ss.SessionEventSinkPOA;

import org.omg.CORBA.Object;

import scs.core.servant.ComponentContext;

/**
 * Implementação dummy da faceta EventSink.
 * 
 */
public final class EventSinkImpl extends SessionEventSinkPOA {
  private ComponentContext context;

  /**
   * Construtor padrão.
   * 
   * @param context Contexto ao qual essa faceta pertence.
   */
  public EventSinkImpl(ComponentContext context) {
    this.context = context;
  }

  @Override
  public Object _get_component() {
    return this.context.getIComponent();
  }

  public void push(SessionEvent arg0) {
    System.out.println("Evento Push recebido. Tipo: " + arg0.type);
  }

  public void disconnect() {
    System.out.println("Evento Disconnect recebido.");
  }
}
