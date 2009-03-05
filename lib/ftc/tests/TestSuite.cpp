/*
* tests/TestSuite.h
*/

#ifndef TESTSUITE_H_
#define TESTSUITE_H_

#include "config.h"
#include <cxxtest/TestSuite.h>
#include <time.h>
#include <stdio.h>
#include <sys/time.h>

#include <ftc.h>

char buffer[256];

class TestSuite: public CxxTest::TestSuite {
    double diffTime( struct timeval* t_start, struct timeval* t_finish )
    {
      return t_finish->tv_sec - t_start->tv_sec + (t_finish->tv_usec - t_start->tv_usec) / 1.e6 ;
    }

  public:
    void setUP() { }

//    void testConstructor()
//    {
//      sprintf(buffer, "%s/20b", SERVER_TMP_PATH) ;
//      bool writable = true ;
//      unsigned long size = 20 ;
//      ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//      delete ch ;
//    }
// 
//    void testOpenFILE_NOT_FOUND()
//    {
//      sprintf(buffer, "%s/FILE_NOT_FOUND", SERVER_TMP_PATH) ;
//      bool writable = true ;
//      unsigned long size = 20 ;
//      try {
//        ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//        TS_ASSERT_THROWS(ch->open( true ), Error::FILE_NOT_FOUND ) ;
//        TS_ASSERT( !ch->isOpen() ) ;
//        TS_ASSERT_THROWS( ch->close(), Error::FILE_NOT_OPENED ) ;
//        delete ch ;
//      } catch (const char* e) {
//        printf(e);
//      }
//    }

//   void testOpenNO_PERMISSION()
//   {
//     const char* id = "/tmp/NO_PERMISSION" ;
//     bool writable = true ;
//     unsigned long size = 20 ;
//     const char* ACCESS_KEY = "Key" ;
//     ftc* ch = new ftc( id, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS( ch->open( true ), Error::NO_PERMISSION ) ;
//     TS_ASSERT( !ch->isOpen() ) ;
//     TS_ASSERT_THROWS( ch->close(), Error::FILE_NOT_OPENED ) ;
//     delete ch ;
//   }

    void testOpen20b()
    {
      sprintf(buffer, "%s/20b", SERVER_TMP_PATH) ;
      bool writable = false ;
      unsigned long size = 20 ;
      ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
      TS_ASSERT_THROWS_NOTHING( ch->open( true ) ) ;
      TS_ASSERT( ch->isOpen() ) ;
      TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
      delete ch ;
    }

//    void testWritableANDReadOnlyFALSE()
//    {
//      sprintf(buffer, "%s/20b", SERVER_TMP_PATH) ;
//      bool writable = false ;
//      unsigned long size = 20 ;
//      ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//      TS_ASSERT_THROWS( ch->open( false ), const char* ) ;
//      TS_ASSERT( !ch->isOpen() ) ;
//      delete ch ;
//    }
// 
//    void testCLOSE()
//    {
//      sprintf(buffer, "%s/20b", SERVER_TMP_PATH) ;
//      bool writable = true ;
//      unsigned long size = 20 ;
//      ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//      TS_ASSERT_THROWS( ch->close(), Error::FILE_NOT_OPENED ) ;
//      delete ch ;
//    }
// 
//    void testTRUNCATE()
//    {
//      sprintf(buffer, "%s/20b", SERVER_TMP_PATH) ;
//      bool writable = true ;
//      unsigned long size = 20 ;
//      ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//      TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//      TS_ASSERT_THROWS_NOTHING( ch->truncate( 10 ) ) ;
//      TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//      delete ch ;
//    }
// 
//    void testTruncateReadOnly()
//    {
//      sprintf(buffer, "%s/20b", SERVER_TMP_PATH) ;
//      bool writable = true ;
//      unsigned long size = 20 ;
//      ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//      TS_ASSERT_THROWS_NOTHING( ch->open( true ) ) ;
//      TS_ASSERT_THROWS( ch->truncate( 10 ), Error::IS_READ_ONLY_FILE ) ;
//      TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//      delete ch ;
//    }
// 
//    void testSETPOSITION()
//    {
//      sprintf(buffer, "%s/20b", SERVER_TMP_PATH) ;
//      bool writable = true ;
//      unsigned long size = 20 ;
//      ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//      TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//      TS_ASSERT_THROWS_NOTHING( ch->setPosition( 10 ) ) ;
//      TS_ASSERT_EQUALS( ch->getPosition(), (unsigned long) 10 ) ;
//      TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//      delete ch ;
//    }

//   void testGETPOSITION()
//   {
//     const char* id = "/tmp/20b" ;
//     bool writable = true ;
//     unsigned long size = 20 ;
//     const char* ACCESS_KEY = "Key" ;
//     ftc* ch = new ftc( id, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//     size_t nbytes = 2 ;
//     char* data = new char[ nbytes ] ;
//     ch->read( data, nbytes, 0 );
//     TS_ASSERT_EQUALS( ch->getPosition(), (unsigned long) 2 ) ;
//     TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//     delete ch ;
//   }

//   void testGETSIZE()
//   {
//     sprintf(buffer, "%s/100b", SERVER_TMP_PATH) ;
//     bool writable = true ;
//     unsigned long size = 100 ;
//     ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//     TS_ASSERT_EQUALS( ch->getSize(), (unsigned long) 100 ) ;
//     TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//     delete ch ;
//   }
//
//  void testREAD()
//  {
//    sprintf(buffer, "%s/10b", SERVER_TMP_PATH) ;
//    bool writable = true ;
//    unsigned long size = 10 ;
//    ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//    TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//    size_t nbytes = 7 ;
//    char* data = new char[ nbytes ] ;
//    ch->read( data, nbytes, 0 ) ;
//    TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//    delete ch ;
//  }
//
//   void testWRITE()
//   {
//     sprintf(buffer, "%s/write", SERVER_TMP_PATH) ;
//     bool writable = true ;
//     unsigned long size = 14 ;
//     ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//     size_t nbytes = 5 ;
//     char* data = "teste" ;
//     ch->write( data, nbytes, 7 ) ;
//     TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//     delete ch ;
//   }
//
//   void testWRITE1Mb()
//   {
//     sprintf(buffer, "%s/1WMb", SERVER_TMP_PATH) ;
//     bool writable = true ;
//     unsigned long size = 1000000 ;
//     ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//     size_t nbytes = size ;
//     char* data = new char[ size ] ;
//     unsigned int x ;
//     for( x = 0; x < size ; x++ ) {
//       data[ x ] = '*' ;
//     }
//     try { ch->write( data, nbytes, 0 ) ; } catch (const char* m) { printf("%s",m); }
//     TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//     delete ch ;
//   }

  void testREAD10Mb()
  {
    struct timeval t_start, t_finish ;
    sprintf(buffer, "%s/10Mb", SERVER_TMP_PATH) ;
    bool writable = true ;
    unsigned long size = 10000000 ;
    ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
    TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
    size_t nbytes = 10000000 ;
    char* data = new char[ nbytes ] ;
    gettimeofday( &t_start, NULL ) ;
    ch->read( data, nbytes, 0 ) ;
    sprintf(buffer, "%s/10MbRCVED", LOCAL_TMP_PATH) ;
    FILE* fp = fopen( buffer, "w" ) ;
    if ( fp == NULL ) {
      TS_FAIL( "An error occurred while attempting to create a file." ) ;
    } else {
      fwrite( data, sizeof(data[0]), nbytes, fp ) ;
      fclose( fp ) ;
    }
    gettimeofday( &t_finish, NULL ) ;
    printf( "Time elapsed: %.9f\n", diffTime(&t_start, &t_finish) ) ;
    TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
    delete data ;
    delete ch ;
  }
//
//   void testREAD50Mb()
//   {
//     struct timeval t_start, t_finish ;
//     sprintf(buffer, "%s/50Mb", SERVER_TMP_PATH) ;
//     bool writable = true ;
//     unsigned long size = 50000000 ;
//     ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//     size_t nbytes = 50000000 ;
//     char* data = new char[ nbytes ] ;
//     gettimeofday( &t_start, NULL ) ;
//     ch->read( data, nbytes, 0 ) ;
//     sprintf(buffer, "%s/50MbRCVED", LOCAL_TMP_PATH) ;
//     FILE* fp = fopen( buffer, "w" ) ;
//     if ( fp == NULL ) {
//       TS_FAIL( "An error occurred while attempting to create a file." ) ;
//     } else {
//       fwrite( data, sizeof(data[0]), nbytes, fp ) ;
//       fclose( fp ) ;
//     }
//     gettimeofday( &t_finish, NULL ) ;
//     printf( "Time elapsed: %.9f\n", diffTime(&t_start, &t_finish) ) ;
//     TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//     delete data ;
//     delete ch ;
//   }
//
//   void testREAD100Mb()
//   {
//     struct timeval t_start, t_finish ;
//     sprintf(buffer, "%s/100Mb", SERVER_TMP_PATH) ;
//     bool writable = true ;
//     unsigned long size = 100000000 ;
//     ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//     size_t nbytes = 100000000 ;
//     char* data = new char[ nbytes ] ;
//     gettimeofday( &t_start, NULL ) ;
//     ch->read( data, nbytes, 0 ) ;
//     sprintf(buffer, "%s/100MbRCVED", LOCAL_TMP_PATH) ;
//     FILE* fp = fopen( buffer, "w" ) ;
//     if ( fp == NULL ) {
//       TS_FAIL( "An error occurred while attempting to create a file." ) ;
//     } else {
//       fwrite( data, sizeof(data[0]), nbytes, fp ) ;
//       fclose( fp ) ;
//     }
//     gettimeofday( &t_finish, NULL ) ;
//     printf( "Time elapsed: %.9f\n", diffTime(&t_start, &t_finish) ) ;
//     TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//     delete data ;
//     delete ch ;
//   }
//
//   void testREAD200Mb()
//   {
//     struct timeval t_start, t_finish ;
//     sprintf(buffer, "%s/200Mb", SERVER_TMP_PATH) ;
//     bool writable = true ;
//     unsigned long size = 200000000 ;
//     ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//     size_t nbytes = 200000000 ;
//     char* data = new char[ nbytes ] ;
//     gettimeofday( &t_start, NULL ) ;
//     ch->read( data, nbytes/4, 0 ) ;
//     ch->read( data+50000000, nbytes/4, 50000000 ) ;
//     ch->read( data+100000000, nbytes/4, 100000000 ) ;
//     ch->read( data+150000000, nbytes/4, 150000000 ) ;
//     sprintf(buffer, "%s/200MbRCVED", LOCAL_TMP_PATH) ;
//     FILE* fp = fopen( buffer, "w" ) ;
//     if ( fp == NULL ) {
//       TS_FAIL( "An error occurred while attempting to create a file." ) ;
//     } else {
//       fwrite( data, sizeof(data[0]), nbytes, fp ) ;
//       fclose( fp ) ;
//     }
//     gettimeofday( &t_finish, NULL ) ;
//     printf( "Time elapsed: %.9f\n", diffTime(&t_start, &t_finish) ) ;
//     TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//     delete data ;
//     delete ch ;
//   }
//
//   void testREAD300Mb()
//   {
//     struct timeval t_start, t_finish ;
//     sprintf(buffer, "%s/300Mb", SERVER_TMP_PATH) ;
//     bool writable = true ;
//     unsigned long size = 300000000 ;
//     ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS_NOTHING( ch->open( false ) ) ;
//     size_t nbytes = 300000000 ;
//     char* data = new char[ nbytes ] ;
//     gettimeofday( &t_start, NULL ) ;
//     ch->read( data, nbytes/6, 0 ) ;
//     ch->read( data+50000000, nbytes/6, 50000000 ) ;
//     ch->read( data+100000000, nbytes/6, 100000000 ) ;
//     ch->read( data+150000000, nbytes/6, 150000000 ) ;
//     ch->read( data+200000000, nbytes/6, 200000000 ) ;
//     ch->read( data+250000000, nbytes/6, 250000000 ) ;
//     sprintf(buffer, "%s/300MbRCVED", LOCAL_TMP_PATH) ;
//     FILE* fp = fopen( buffer, "w" ) ;
//     if ( fp == NULL ) {
//       TS_FAIL( "An error occurred while attempting to create a file." ) ;
//     } else {
//       fwrite( data, sizeof(data[0]), nbytes, fp ) ;
//       fclose( fp ) ;
//     }
//     gettimeofday( &t_finish, NULL ) ;
//     printf( "Time elapsed: %.9f\n", diffTime(&t_start, &t_finish) ) ;
//     TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//     delete data ;
//     delete ch ;
//   }
//
//   void testREAD3Gb()
//   {
//     struct timeval t_start, t_finish ;
//     sprintf(buffer, "%s/3Gb", SERVER_TMP_PATH) ;
//     bool writable = true ;
//     unsigned long long size = 3000000000LL ;
//     ftc* ch = new ftc( buffer, writable, size, SERVER_HOST, SERVER_PORT, ACCESS_KEY) ;
//     TS_ASSERT_THROWS_NOTHING( ch->open( true ) ) ;
//     size_t nbytes = 500000000 ;
//     char* data = new char[ nbytes ] ;
//     gettimeofday( &t_start, NULL ) ;
//     sprintf(buffer, "%s/3GbRCVED", LOCAL_TMP_PATH) ;
//     FILE* fp = fopen( buffer, "w" ) ;
//     if ( fp == NULL ) {
//       TS_FAIL( "An error occurred while attempting to create a file." ) ;
//     } else {
//       ch->read( data, nbytes/10, 0 ) ;
//       ch->read( data+50000000, nbytes/10, 50000000 ) ;
//       ch->read( data+100000000, nbytes/10, 100000000 ) ;
//       ch->read( data+150000000, nbytes/10, 150000000 ) ;
//       ch->read( data+200000000, nbytes/10, 200000000 ) ;
//       ch->read( data+250000000, nbytes/10, 250000000 ) ;
//       ch->read( data+300000000, nbytes/10, 300000000 ) ;
//       ch->read( data+350000000, nbytes/10, 350000000 ) ;
//       ch->read( data+400000000, nbytes/10, 400000000 ) ;
//       ch->read( data+450000000, nbytes/10, 450000000 ) ;
//       fwrite( data, sizeof(data[0]), 500000000, fp ) ;
//       ch->read( data, nbytes/10, 500000000 ) ;
//       ch->read( data+50000000,  nbytes/10, 550000000 ) ;
//       ch->read( data+100000000, nbytes/10, 600000000 ) ;
//       ch->read( data+150000000, nbytes/10, 650000000 ) ;
//       ch->read( data+200000000, nbytes/10, 700000000 ) ;
//       ch->read( data+250000000, nbytes/10, 750000000 ) ;
//       ch->read( data+300000000, nbytes/10, 800000000 ) ;
//       ch->read( data+350000000, nbytes/10, 850000000 ) ;
//       ch->read( data+400000000, nbytes/10, 900000000 ) ;
//       ch->read( data+450000000, nbytes/10, 950000000 ) ;
//       fwrite( data, sizeof(data[0]), 500000000, fp ) ;
//       ch->read( data, nbytes/10, 1000000000 ) ;
//       ch->read( data+50000000,  nbytes/10, 1050000000 ) ;
//       ch->read( data+100000000, nbytes/10, 1100000000 ) ;
//       ch->read( data+150000000, nbytes/10, 1150000000 ) ;
//       ch->read( data+200000000, nbytes/10, 1200000000 ) ;
//       ch->read( data+250000000, nbytes/10, 1250000000 ) ;
//       ch->read( data+300000000, nbytes/10, 1300000000 ) ;
//       ch->read( data+350000000, nbytes/10, 1350000000 ) ;
//       ch->read( data+400000000, nbytes/10, 1400000000 ) ;
//       ch->read( data+450000000, nbytes/10, 1450000000 ) ;
//       fwrite( data, sizeof(data[0]), 500000000, fp ) ;
//       ch->read( data, nbytes/10, 1500000000 ) ;
//       ch->read( data+50000000,  nbytes/10, 1550000000 ) ;
//       ch->read( data+100000000, nbytes/10, 1600000000 ) ;
//       ch->read( data+150000000, nbytes/10, 1650000000 ) ;
//       ch->read( data+200000000, nbytes/10, 1700000000 ) ;
//       ch->read( data+250000000, nbytes/10, 1750000000 ) ;
//       ch->read( data+300000000, nbytes/10, 1800000000 ) ;
//       ch->read( data+350000000, nbytes/10, 1850000000 ) ;
//       ch->read( data+400000000, nbytes/10, 1900000000 ) ;
//       ch->read( data+450000000, nbytes/10, 1950000000 ) ;
//       fwrite( data, sizeof(data[0]), 500000000, fp ) ;
//       ch->read( data, nbytes/10, 2000000000 ) ;
//       ch->read( data+50000000,  nbytes/10, 2050000000 ) ;
//       ch->read( data+100000000, nbytes/10, 2100000000 ) ;
//       ch->read( data+150000000, nbytes/10, 2150000000LL ) ;
//       ch->read( data+200000000, nbytes/10, 2200000000LL ) ;
//       ch->read( data+250000000, nbytes/10, 2250000000LL ) ;
//       ch->read( data+300000000, nbytes/10, 2300000000LL ) ;
//       ch->read( data+350000000, nbytes/10, 2350000000LL ) ;
//       ch->read( data+400000000, nbytes/10, 2400000000LL ) ;
//       ch->read( data+450000000, nbytes/10, 2450000000LL ) ;
//       fwrite( data, sizeof(data[0]), 500000000, fp ) ;
//       ch->read( data, nbytes/10, 2500000000LL ) ;
//       ch->read( data+50000000,  nbytes/10, 2550000000LL ) ;
//       ch->read( data+100000000, nbytes/10, 2600000000LL ) ;
//       ch->read( data+150000000, nbytes/10, 2650000000LL ) ;
//       ch->read( data+200000000, nbytes/10, 2700000000LL ) ;
//       ch->read( data+250000000, nbytes/10, 2750000000LL ) ;
//       ch->read( data+300000000, nbytes/10, 2800000000LL ) ;
//       ch->read( data+350000000, nbytes/10, 2850000000LL ) ;
//       ch->read( data+400000000, nbytes/10, 2900000000LL ) ;
//       ch->read( data+450000000, nbytes/10, 2950000000LL ) ;
//       fwrite( data, sizeof(data[0]), 500000000, fp ) ;
//       fclose( fp ) ;
//     }
//     gettimeofday( &t_finish, NULL ) ;
//     printf( "Time elapsed: %.9f\n", diffTime(&t_start, &t_finish) ) ;
//     TS_ASSERT_THROWS_NOTHING( ch->close() ) ;
//     delete data ;
//     delete ch ;
//   }

} ;

#endif
