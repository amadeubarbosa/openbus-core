/*
* tests/TestSuite.h
*/

#ifndef TESTSUITE_H_
#define TESTSUITE_H_

#include "config.h"
#include <cxxtest/TestSuite.h>
#include <time.h>
#include <typeinfo>
#include <iostream>
#include <string>
#include <sys/time.h>
#include <openssl/md5.h>

#include <ftc.h>

#define KEY_SIZE 16
#define LARGESIZE 4*1024*1024*1024ull

using namespace std;

class TestSuite: public CxxTest::TestSuite {
  private:
    unsigned char md5_key[KEY_SIZE];

    double diffTime( struct timeval* t_start, struct timeval* t_finish )
    {
      return t_finish->tv_sec - t_start->tv_sec + (t_finish->tv_usec - t_start->tv_usec) / 1.e6 ;
    }

  public:
    void setUP() { }

    void testConstructor()
    {
      string filename(SERVER_TMP_PATH);  
      filename += "/test";
	  
	  MD5((const unsigned char*)filename.c_str(),filename.size(),md5_key);
      
      ftc ch(filename.c_str(), true, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
    }

    void testOpenFILE_NOT_FOUND()
    {
      string filename(SERVER_TMP_PATH);  
      filename += "/FILE_NOT_FOUND";
	  
      MD5((const unsigned char*)filename.c_str(),filename.size(),md5_key);
      
      try {
        ftc ch( filename.c_str(), true, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
        TS_ASSERT_THROWS(ch.open( true ), InvalidKeyException) ;
        TS_ASSERT( !ch.isOpen() ) ;
        TS_ASSERT_THROWS( ch.close(), FileNotOpenException ) ;
      } catch (const char* e) {
        printf(e);
      }
    }

    void testOpentest()
    {
      string filename(SERVER_TMP_PATH);  
      filename += "/test";
	  MD5((const unsigned char*)filename.c_str(),filename.size(),md5_key);
      ftc ch( filename.c_str(), false, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
      TS_ASSERT_THROWS_NOTHING( ch.open( true ) ) ;
      TS_ASSERT( ch.isOpen() ) ;
      TS_ASSERT_THROWS_NOTHING( ch.close() ) ;
    }

    void testWritableANDReadOnlyFALSE()
    {
      string filename(SERVER_TMP_PATH);  
      filename += "/test";
	  MD5((const unsigned char*)filename.c_str(),filename.size(),md5_key);
      ftc ch( filename.c_str(), false, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
      TS_ASSERT_THROWS( ch.open( false ), NoPermissionException ) ;
      TS_ASSERT( !ch.isOpen() ) ;
    }

    void testCLOSE()
    {
      string filename(SERVER_TMP_PATH);  
      filename += "/test";
	  MD5((const unsigned char*)filename.c_str(),filename.size(),md5_key);
      ftc ch( filename.c_str(), true, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
      TS_ASSERT_THROWS( ch.close(), FileNotOpenException ) ;
      TS_ASSERT_THROWS_NOTHING( ch.open( false ) ) ;
      TS_ASSERT_THROWS_NOTHING( ch.close() ) ;
    }

    void testSIZE()
    {
      string filename(SERVER_TMP_PATH);  
      filename += "/test";
	  MD5((const unsigned char*)filename.c_str(),filename.size(),md5_key);
      ftc ch( filename.c_str(), true, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
      TS_ASSERT_THROWS_NOTHING( ch.open( false ) ) ;
      TS_ASSERT_THROWS_NOTHING( ch.setSize( 0 ) ) ;
      TS_ASSERT_EQUALS( ch.getSize(),  0ull ) ;
      TS_ASSERT_THROWS_NOTHING( ch.setSize( 10 ) ) ;
      TS_ASSERT_EQUALS( ch.getSize(),  10ull ) ;
      TS_ASSERT_THROWS_NOTHING( ch.setSize( 1024*1024 ) ) ;
      TS_ASSERT_EQUALS( ch.getSize(),  1024*1024ull ) ;
      TS_ASSERT_THROWS_NOTHING( ch.setSize( 0 ) ) ;
      TS_ASSERT_EQUALS( ch.getSize(),  0ull ) ;
      TS_ASSERT_THROWS_NOTHING( ch.setSize( LARGESIZE ) ) ;
      TS_ASSERT_EQUALS( ch.getSize(),  LARGESIZE ) ;
      TS_ASSERT_THROWS_NOTHING( ch.close() ) ;
    }

    void testSetSizeReadOnly()
    {
      string filename(SERVER_TMP_PATH);  
      filename += "/test";
	  MD5((const unsigned char*)filename.c_str(),filename.size(),md5_key);
      ftc ch( filename.c_str(), true, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
      TS_ASSERT_THROWS_NOTHING( ch.open( true ) ) ;
      TS_ASSERT_THROWS( ch.setSize( 10 ), NoPermissionException ) ;
      TS_ASSERT_THROWS_NOTHING( ch.close() ) ;
    }

    void testSETPOSITION()
    {
      string filename(SERVER_TMP_PATH);  
      filename += "/test" ;
	  MD5((const unsigned char*)filename.c_str(),filename.size(),md5_key);
      ftc ch( filename.c_str(), true, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
      TS_ASSERT_THROWS_NOTHING( ch.open( false ) ) ;
      TS_ASSERT_THROWS_NOTHING( ch.setPosition( 1024 ) ) ;
      TS_ASSERT_EQUALS( ch.getPosition(), 1024ull ) ;
      TS_ASSERT_THROWS_NOTHING( ch.setPosition( 0 ) ) ;
      TS_ASSERT_EQUALS( ch.getPosition(), 0ull ) ;
      TS_ASSERT_THROWS_NOTHING( ch.setPosition( LARGESIZE ) ) ;
      TS_ASSERT_EQUALS( ch.getPosition(), LARGESIZE ) ;
      TS_ASSERT_THROWS_NOTHING( ch.close() ) ;
    }

   void testReadAndWrite()
   {
      string filename(SERVER_TMP_PATH);  
      filename += "/test";
      unsigned long long nbytes = filename.size();
	  MD5((const unsigned char*)filename.c_str(), nbytes ,md5_key);
      ftc ch( filename.c_str(), true, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
      TS_ASSERT_THROWS_NOTHING( ch.open( false ) ) ;
      
      TS_ASSERT_EQUALS(ch.write( filename.c_str(), nbytes , 0 ) , nbytes )  ;
      
      char data[ nbytes ] ;
      TS_ASSERT_EQUALS(ch.read( data, nbytes, 0 ), nbytes) ;
      //for(unsigned int i = 0 ; i < nbytes ; i++)
      //    cout << data[i] << endl;
      TS_ASSERT_EQUALS(filename.compare(data), 0) ;
      TS_ASSERT_THROWS_NOTHING( ch.close() ) ;
   }

    void testReadAndWriteAfter3GB()
    {
      string filename(SERVER_TMP_PATH);  
      filename += "/test";
      unsigned long long nbytes = filename.size();
	  MD5((const unsigned char*)filename.c_str(), nbytes ,md5_key);
      ftc ch( filename.c_str(), true, SERVER_HOST, SERVER_PORT, (const char*)md5_key) ;
      TS_ASSERT_THROWS_NOTHING( ch.open( false ) ) ;
      
      TS_ASSERT_EQUALS(ch.write( filename.c_str(), nbytes , LARGESIZE ) , nbytes )  ;
      
      char data[ nbytes ] ;
      TS_ASSERT_EQUALS(ch.read( data, nbytes, LARGESIZE ), nbytes) ;
      TS_ASSERT_EQUALS(filename.compare(data), 0) ;
      TS_ASSERT_THROWS_NOTHING( ch.close() ) ;
    }

} ;

#endif
