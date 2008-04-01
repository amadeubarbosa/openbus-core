/*
* tests/TestCo.h
*/

#ifndef TESTCO_H_
#define TESTCO_H_

#include <lua.hpp>
#include <cxxtest/TestSuite.h>
#include "../src/RemoteFileChannel.h"

using namespace remotefilechannel ;

class TestCoSuite: public CxxTest::TestSuite {
  public:
    void setUP() { }

    void testOne()
    {
      const char* id = "/tmp/10b" ;
      bool writable = true ;
      unsigned long size = 10 ;
      const char* accessKey = "Key" ;
      const char* host = "localhost" ;
      unsigned long port = 45000 ;
      try {
        RemoteFileChannel* rfc = new RemoteFileChannel( id, writable, size, host, port, accessKey) ;
        lua_State* L = RemoteFileChannel::getLuaVM() ;
        if ( luaL_dofile( L, "TestRecvSend.lua" ) != 0 )
        {
          printf( "Erro ao carregar arquivo TestRecvSend.lua" ) ;
        }
        rfc->open( true ) ;
        char* data = new char[10] ;
        rfc->read( data, 10, 0 ) ;
        rfc->close() ;
        delete rfc ;
    /* como faz ? */
      } catch( const char* errmsg ) {
        printf("%s\n", errmsg ) ;
      }
    }

} ;


#endif
