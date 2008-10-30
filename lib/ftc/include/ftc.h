/*
** ftc.h
*/

#ifndef  FTC_H_
#define  FTC_H_

#include <stdlib.h>

typedef struct lua_State Lua_State ;

namespace Error {
  struct FILE_NOT_FOUND     { } ;
  struct NO_PERMISSION      { } ;
  struct FILE_NOT_OPENED    { } ;
  struct IS_READ_ONLY_FILE  { } ;
}

class ftc {
    static Lua_State* LuaVM ;
    static void setEnv() ;
  public:
    static void setLuaVM( Lua_State* L ) ;
    static Lua_State* getLuaVM() ;
    ftc( const char* id, bool writable, unsigned long long size, const char* host, \
                        unsigned long port, const char* accessKey ) ;
    ~ftc() ;
    void open( bool readonly ) ;
    bool isOpen() ;
    void close() ;
    void truncate( unsigned long long size ) ;
    void setPosition( unsigned long long position ) ;
    unsigned long long getPosition() ;
    unsigned long long getSize() ;
    void read( char* data, unsigned long long nbytes, unsigned long long position ) ;
    void write( char* data, unsigned long long nbytes, unsigned long long position ) ;
} ;

#endif
