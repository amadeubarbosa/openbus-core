/*
* oil/luaidl/cpp/types.h
*/

#ifndef LUAIDLCPPTYPES_H_
#define LUAIDLCPPTYPES_H_

namespace luaidl {
  namespace cpp   {
    namespace types {
      typedef const char* String ;
      typedef signed long Long ;
    }

    template <class T>
    class sequence {
      private:
        T** data ;
        int max ;
        int len ;
      public:
        sequence ( int _max=256 )
        {
          len = 0 ;
          max = _max ;
          data = new T*[ max ] ;
        }

        ~sequence ( void ) { delete data ; }

        int maximum ( void )
        {
          return max ;
        }

        int length ( void )
        {
          return len ;
        }

        void newmember( T* val )
        {
          data[ len ] = val ;
          len++ ;
        }

        T* getmember( int idx )
        {
          return data[ idx ] ;
        }

    } ;
  }
}

#endif
