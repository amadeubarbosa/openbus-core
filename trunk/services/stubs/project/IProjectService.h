/*
** IProjectService.h
*/

#ifndef IPROJECTSERVICE_H_
#define IPROJECTSERVICE_H_

#include <lua.hpp>
#include <scs/core/luaidl/cpp/types.h>
#include <stubs/IDataService.h>

using namespace luaidl::cpp::types;

namespace projectService {

  class IFile;

  class IProject : public dataService::IDataEntry {
    public:
      IProject();
      ~IProject();
      String getId();
      String getName();
      String getOwner();
      IFile* getRootFile();
      void close();
  };

  typedef luaidl::cpp::sequence<IProject> ProjectList;
  typedef luaidl::cpp::sequence<IFile> FileList;

  class IFile : public dataService::IDataEntry {
    public:
      IFile();
      ~IFile();
      String getName();
      char* getPath();
      long long getSize();
      bool canRead();
      bool canWrite();
      bool isDirectory();
      FileList* getFiles();
      IProject* getProject();
      bool createFile(char* name, char* type);
      bool createDirectory (char* name);
      bool Delete();
      bool rename (char* newName);
      bool moveFile(IFile* newParent);
      bool copyFile(IFile* newParent);
      void close();
  };

}

#endif
