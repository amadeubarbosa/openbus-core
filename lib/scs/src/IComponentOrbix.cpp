/*
** IComponentOrbix.cpp
*/

#include <scs/core/IComponentOrbix.h>

#ifdef VERBOSE
using namespace std;
#endif

namespace scs {
  namespace core {
    IComponentImpl::IComponentImpl(ComponentContext* context) {
    #ifdef VERBOSE
      cout << "[IComponentImpl::IComponentImpl() BEGIN]" << endl;
    #endif
      this->context = context;
      this->facets = &(context->getFacetDescs());
    #ifdef VERBOSE
      cout << "[IComponentImpl::IComponentImpl() END]" << endl;
    #endif
    }

    IComponentImpl::~IComponentImpl() {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::~IComponentImpl() BEGIN]" << endl;
    #endif
    #ifdef VERBOSE
      cout << "[IComponentImpl::~IComponentImpl() END]" << endl;
    #endif
    }

    void* IComponentImpl::instantiate(ComponentContext* context) {
      return (void*) new IComponentImpl(context);
    }

    void IComponentImpl::startup() IT_THROW_DECL((CORBA::SystemException, scs::core::StartupFailed)) {}
    void IComponentImpl::shutdown() IT_THROW_DECL((CORBA::SystemException, scs::core::ShutdownFailed)) {}

    CORBA::Object_ptr IComponentImpl::getFacet(const char* facet_interface) IT_THROW_DECL((CORBA::SystemException)) {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::getFacet() BEGIN]" << endl;
      cout << "\t[Interface da faceta sendo procurada: '" << facet_interface << "']" << endl;
    #endif
      CORBA::Object_var o;
      std::string temp(" NÃO");
      FacetDescription* f = NULL;
      std::map<std::string, FacetDescription>::iterator it;
      for (it = facets->begin(); it != facets->end(); it++) {
        f = &(*it).second;
        if (strcmp(f->interface_name, facet_interface) == 0) {
          o = f->facet_ref;
          temp = "";
          break;
        }
      }
    #ifdef VERBOSE
      cout << "\t[Faceta de interface '" << facet_interface << "'" << temp << " encontrada]" << endl;
      cout << "[IComponentImpl::getFacet() END]" << endl;
    #endif
      return o._retn();
    }

    CORBA::Object_ptr IComponentImpl::getFacetByName(const char* facet) IT_THROW_DECL((CORBA::SystemException)) {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::getFacetByName() BEGIN]" << endl;
      cout << "\t[Nome da faceta sendo procurada: '" << facet << "']" << endl;
    #endif
      CORBA::Object_var o;
      std::string temp("");
      std::map<std::string, FacetDescription>::const_iterator it = facets->find(facet);
      if (it != facets->end())
        o = ((FacetDescription) it->second).facet_ref;
      else
        temp = " NÃO";
    #ifdef VERBOSE
      cout << "\t[Faceta de nome '" << facet << "'" << temp << " encontrada]" << endl;
      cout << "[IComponentImpl::getFacetByName() END]" << endl;
    #endif
      return o._retn();
    }

    ComponentId* IComponentImpl::getComponentId() IT_THROW_DECL((CORBA::SystemException)) {
    #ifdef VERBOSE
      cout << "\n\n[IComponentImpl::getComponentId() BEGIN]" << endl;
    #endif
      ComponentId_var cId = new ComponentId(this->context->getComponentId());
    #ifdef VERBOSE
      cout << "\t[componentID.name: " << cId->name.in() << "]" << endl;
      cout << "\t[componentID.major_version: " << cId->major_version << "]" << endl;
      cout << "\t[componentID.minor_version: " << cId->minor_version << "]" << endl;
      cout << "\t[componentID.patch_version: " << cId->patch_version << "]" << endl;
      cout << "\t[componentID.platform_spec: " << cId->platform_spec.in() << "]" << endl;
      cout << "[IComponentImpl::getComponentId() END]" << endl;
    #endif
      return cId._retn();
    }
  }
}
