/*
** IProjectService.h
*/

#ifndef IPROJECTSERVICE_H_
#define IPROJECTSERVICE_H_

#include <lua.hpp>
#include <openbus/oil/luaidl/cpp/types.h>

using namespace luaidl::cpp::types ;

namespace projectService {

  typedef luaidl::cpp::sequence<char> OctetSeq ;

  class IFile ;

  class IProject {
    public:
      IProject() ;
      ~IProject() ;
      String getId() ;
      String getName() ;
      String getOwner() ;
      IFile* getRootFile() ;
      void close() ;
  } ;

  typedef luaidl::cpp::sequence<IProject> ProjectList ;
  typedef luaidl::cpp::sequence<IFile> FileList ;

  struct DataChannel {
    char* host ;
    unsigned short port ;
    OctetSeq* accessKey ;
    OctetSeq* fileIdentifier ;
    bool writable ;
    long long fileSize ;
  } ;

  class IFile {
    public:
      IFile() ;
      ~IFile() ;
      String getName() ;
      char* getPath() ;
      long long getSize() ;
      bool canRead() ;
      bool canWrite() ;
      bool isDirectory() ;
      FileList* getFiles() ;
      IProject* getProject() ;
      bool createFile( char* name, char* type ) ;
      bool createDirectory ( char* name ) ;
      bool Delete() ;
      bool rename ( char* newName ) ;
      bool moveFile( IFile* newParent ) ;
      bool copyFile( IFile* newParent ) ;
      DataChannel* getDataChannel() ;
      void close() ;
  } ;

  class IProjectService {
    private:
    public:
      IProjectService() ;
      ~IProjectService() ;
      ProjectList* getProjects() ;
      IProject* getProject ( char* name ) ;
      IFile* getFile( String path ) ;
      IProject* createProject( char* name ) ;
      bool deleteProject( IProject* aProject) ;
  } ;
}

#endif
