/*
**  IDataService.h
*/

#ifndef IDATASERVICE_H_
#define IDATASERVICE_H_

#include <lua.hpp>
#include <scs/core/luaidl/cpp/types.h>
#include <scs/core/IComponentOil.h>

#include <exception>

using namespace luaidl::cpp::types;

namespace dataService {
  typedef luaidl::cpp::sequence<char> OctetSeq;

  typedef luaidl::cpp::sequence<luaidl::cpp::types::Any> ValueList;

  typedef char* MetadataName;

  typedef char* MetadataValue;

  struct Metadata {
    MetadataName name;
    MetadataValue value;
  };

  typedef luaidl::cpp::sequence<Metadata> MetadataList;

  typedef char* URI;

  struct DataKey {
    scs::core::ComponentId* service_id;
    URI actual_data_id;
  };

  struct Data {
    DataKey* key;
    MetadataList* metadata;
  };

  typedef luaidl::cpp::sequence<Data> DataList;

  struct DataChannel {
    char* host;
    unsigned short port;
    OctetSeq* accessKey;
    OctetSeq* dataIdentifier;
    bool writable;
    long long dataSize;
  };

  class IDataService;

  class OperationNotSupported : public std::exception {};

  class UnknownType : public std::exception {};

  class IDataEntry {
    public:
      IDataEntry();
      ~IDataEntry();
      DataKey* getKey();
      IDataService* getDataService();
      char* getFacetInterface();
      void copyFrom(DataKey* source_key);
      luaidl::cpp::types::Any* getAttr(char* attr_name);
      ValueList* getAttrs(scs::core::NameList* attrs_name);
      bool setAttr(char* attr_name, luaidl::cpp::types::Any* attr_value);
      bool setAttrs(scs::core::NameList* attrs_name, ValueList* attrs_value);
      DataChannel* getDataChannel();
  };

  class IDataService {
    public:
      IDataService();
      ~IDataService();
      DataList* getRoots();
      DataList* getChildren(DataKey* key);
      DataKey* createData(DataKey* parent_key, MetadataList* metadata);
      DataKey* createDataFrom(DataKey* parent_key, DataKey* source_key);
      bool deleteData(DataKey* key);
      Data* getData(DataKey* key);
      bool _getDataFacet(void* ptr, DataKey* key, char* facet_interface);
      template <class T>
      T* getDataFacet(DataKey* key, char* facet_interface) {
        T* ptr = new T;
        if (!_getDataFacet(ptr, key, facet_interface)) {
          return 0;
        } else {
          return ptr;
        }
      }
      scs::core::NameList* getFacetInterfaces(DataKey* key);
  };
}

#endif
