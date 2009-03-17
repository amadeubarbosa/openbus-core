/*
** ExtendedFacetDescription.h
*/

#ifndef EXTENDEDFACETDESCRIPTION_H_
#define EXTENDEDFACETDESCRIPTION_H_

#include <string>
#include <scs/core/ComponentContextOrbix.h>

namespace scs {
  namespace core {
    class ComponentContext;
    typedef struct ExtFacetDescription {
      std::string name;
      std::string interface_name;
      void* (*instantiator)(ComponentContext* context);
    } ExtendedFacetDescription;
  }
}

#endif
