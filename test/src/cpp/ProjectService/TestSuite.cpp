/*
* ProjectService/TestSuite.cpp
*/

#ifndef PS_TESTSUITE_H
#define PS_TESTSUITE_H

#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <cxxtest/TestSuite.h>
#include <openbus/oil/openbus.h>
// #include <ftc.h>
#include <extras/services/ProjectService/IProjectService.h>

using namespace openbus ;
using namespace std ;

class RGSTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* o ;
    services::IAccessControlService* acs ;
    services::IRegistryService* rgs ;
    common::CredentialManager* credentialManager ;
    common::ClientInterceptor* clientInterceptor ;
    services::Credential* credential ;
    services::Lease* lease ;
    char* RegistryIdentifier;
    services::ServiceOfferList* serviceOfferList ;
    services::Property* property ;
    services::PropertyList* propertyList ;
    services::PropertyValue* propertyValue ;
    services::ServiceOffer* so ;
    scs::core::IComponent* member ;
    projectService::IProjectService* ps ;
    projectService::IProject* projI ;
    projectService::IProject* projII ;
    projectService::IProject* projIII ;

  public:
    void setUP() {
    }

    void testConstructor()
    {
      try {
        o = Openbus::getInstance() ;
        credentialManager = new common::CredentialManager ;
        const char* OPENBUS_HOME = getenv( "OPENBUS_HOME" ) ;
        char path[ 100 ] ;
        if ( OPENBUS_HOME == NULL )
        {
          throw "Error: OPENBUS_HOME environment variable is not defined." ;
        }
        strcpy( path, OPENBUS_HOME ) ;
        clientInterceptor = new common::ClientInterceptor( \
          strcat( path, "/conf/advanced/InterceptorsConfiguration.lua" ), \
          credentialManager ) ;
        o->setclientinterceptor( clientInterceptor ) ;
        acs = o->getACS( "corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0" ) ;
        credential = new services::Credential ;
        lease = new services::Lease ;
        acs->loginByPassword( "tester", "tester", credential, lease ) ;
        credentialManager->setValue( credential ) ;
        rgs = acs->getRegistryService() ;
        serviceOfferList = rgs->find( "ProjectService", NULL ) ;
        TS_ASSERT( serviceOfferList != NULL ) ;
        so = serviceOfferList->getmember(0) ;
        member = so->member ;
        member->loadidlfile( "/home/rcosme/tecgraf/work/openbus/corba_idl/project_service.idl" ) ;
        ps = member->getFacet <projectService::IProjectService> ( "IDL:openbusidl/ps/IProjectService:1.0" ) ;
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testIProjectService() {
      projI = ps->createProject( "projectI" ) ;
      projI = ps->getProject( "projectI" ) ;
      TS_ASSERT_SAME_DATA( projI->getName(), "projectI", 8 ) ;
      TS_ASSERT_SAME_DATA( ps->getFile( "projectI" )->getName(), "projectI", 8 ) ;
      projII = ps->createProject( "projectII" ) ;
      projIII = ps->createProject( "projectIII" ) ;
      TS_ASSERT( projI != NULL ) ;
      TS_ASSERT( projII != NULL ) ;
      TS_ASSERT( projIII != NULL ) ;
      TS_ASSERT( ps->deleteProject( projI ) == true ) ;
    }

    void testIProject() {
      projectService::ProjectList* projectList = ps->getProjects() ;
      projectService::IProject* proj = projectList->getmember(0) ;
      TS_ASSERT_SAME_DATA( proj->getName(), "projectIII", 10 ) ;
      TS_ASSERT( proj->getId() != NULL ) ;
      TS_ASSERT( proj->getOwner() != NULL ) ;
      TS_ASSERT_SAME_DATA( proj->getOwner(), "tester", 6 ) ;
      TS_ASSERT_SAME_DATA( proj->getRootFile()->getName(), "projectIII", 10 ) ;
      proj->close() ;
    }
/*testar getSize...*/
    void testIFile() {
      projectService::IFile* file = ps->getFile( "projectIII" ) ;
      TS_ASSERT_SAME_DATA( file->getName(), "projectIII", 10 ) ;
      TS_ASSERT_SAME_DATA( file->getPath(), "projectIII", 10 ) ;
      TS_ASSERT( file->createFile( "foo", "" ) == true ) ;
      projectService::IFile* foo = ps->getFile( "projectIII/foo" ) ;
      TS_ASSERT( file->createDirectory( "dir" ) == true ) ;
      projectService::IFile* dir = ps->getFile( "projectIII/dir" ) ;
      TS_ASSERT( foo->copyFile( dir ) == true ) ;
/*      TS_ASSERT( foo->moveFile( dir ) == true ) ;
      TS_ASSERT_SAME_DATA( foo->getPath(), "dir/foo", 7 ) ;*/
      ps->getFile( "projectIII/dir" ) ;
      foo->close() ;
      file = ps->getFile( "projectIII" ) ;
      file->getFiles() ;
      file = ps->getFile( "projectIII/foo" ) ;
      TS_ASSERT_SAME_DATA( file->getPath(), "projectIII/foo", 10 ) ;
      TS_ASSERT( file->canRead() == true ) ;
      TS_ASSERT( file->canWrite() == true ) ;
      TS_ASSERT( file->isDirectory() == false ) ;
      TS_ASSERT_SAME_DATA( file->getProject()->getName(), "projectIII", 10 ) ;
      TS_ASSERT( file->Delete() == true ) ;
      TS_ASSERT( ps->deleteProject( projII ) == true ) ;
      TS_ASSERT( ps->deleteProject( projIII ) == true ) ;
    }

//     void testFTC() {
//       try {
//         projectService::ProjectList* projectList = ps->getProjects() ;
//         projectService::IProject* project = projectList->getmember(0) ;
//         cout << project->getName() << endl ;
//         projectService::IFile* file = ps->getFile( "openbus/consumer.lua" ) ;
//         cout << file->getName() << endl ;
//         projectService::DataChannel* ch = file->getDataChannel() ;
//         cout << ch->host << endl ;
//         cout << ch->port << endl ;
//         cout << ch->accessKey->getmember(0) << endl ;
//         cout << ch->fileIdentifier->getmember(0) << endl ;
//         cout << ch->fileSize << endl ;
//         const char* id = ch->fileIdentifier->getmember(0) ;
//         const char* host = ch->host ;
//         bool writable = false ;
//         unsigned long size = ch->fileSize ;
//         unsigned long port = ch->port ;
//         const char* accessKey = ch->accessKey->getmember(0) ;
//         ftc* fch = new ftc( id, writable, size, host, port, accessKey) ;
//         fch->open( true ) ;
//         size_t nbytes = (size_t) size ;
//         char* data = new char[ nbytes ] ;
//         fch->read( data, nbytes, 0 ) ;
//         fch->close() ;
//         FILE* fp = fopen( "/tmp/write", "w" ) ;
//         if ( fp == NULL ) {
//           TS_FAIL( "An error occurred while attempting to create a file." ) ;
//         } else {
//           fwrite( data, sizeof(data[0]), nbytes, fp ) ;
//           fclose( fp ) ;
//         }
//         delete member ;
// 
//         delete serviceOfferList ;
//       } catch ( const char* errmsg ) {
//         TS_FAIL(errmsg) ;
//       }
//     }
} ;

#endif
