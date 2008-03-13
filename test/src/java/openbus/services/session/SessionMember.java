/*
 * $Id$
 */
package openbus.services.session;

import java.util.ArrayList;

import org.omg.CORBA.UserException;
import org.omg.PortableServer.POA;

import scs.core.ComponentId;
import scs.core.FacetDescription;
import scs.core.servant.IComponentServant;

/**
 * Representa um membro que pode participar de sessões.
 * 
 * @author Tecgraf/PUC-Rio
 */
public final class SessionMember extends IComponentServant {
  /**
   * O POA utilizado para ativar as facetas do membro.
   */
  private POA poa;

  /**
   * Cria um membro que pode participar de sessões.
   * 
   * @param poa O POA utilizado para ativar as facetas do membro.
   */
  public SessionMember(POA poa) {
    this.poa = poa;
  }

  /**
   * {@inheritDoc}
   */
  @Override
  protected ArrayList<FacetDescription> createFacets() {
    try {
      ArrayList<FacetDescription> descriptions =
        new ArrayList<FacetDescription>();
      descriptions.add(new FacetDescription("EventSink",
        "IDL:openbusidl/ss/SessionEventSink:1.0", this.poa
          .servant_to_reference(new SessionEventSinkImpl())));
      return descriptions;
    }
    catch (UserException e) {
      e.printStackTrace();
      return null;
    }
  }

  /**
   * {@inheritDoc}
   */
  @Override
  protected boolean doStartup() {
    return true;
  }

  /**
   * {@inheritDoc}
   */
  @Override
  protected boolean doShutdown() {
    return true;
  }

  /**
   * {@inheritDoc}
   */
  @Override
  protected ComponentId createComponentId() {
    return new ComponentId(this.getClass().getName(), 1);
  }
}