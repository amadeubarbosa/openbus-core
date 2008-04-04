/*
* oil/services/ISessionService.h
*/

#ifndef ISESSION_SERVICE_H_
#define ISESSION_SERVICE_H_

#include "../openbus.h"

namespace openbus {
  namespace services {

    typedef Identifier SessionIdentifier;
    typedef Identifier MemberIdentifier ;

    struct SessionEvent {
      String type ;
      String value ;
    } ;

    class SessionEventSink {
      void* ptr_luaimpl ;
      static int _push_bind ( Lua_State* L ) ;
      static int _disconnect_bind ( Lua_State* L ) ;
    public:
      SessionEventSink () ;
      virtual ~SessionEventSink () ;
      virtual void push( SessionEvent* ev ) {} ;
      virtual void disconnect() {} ;
    } ;

    class ISession {
      public:
        ISession() ;
        ~ISession() ;
        void push( SessionEvent* ev ) ;
        void disconnect() ;
        SessionIdentifier getIdentifier( void ) ;
        MemberIdentifier  addMember( scs::core::IComponent* member ) ;
        bool              removeMember( MemberIdentifier memberIdentifier ) ;
      /* nao esta implementado em Lua */
        scs::core::IComponentSeq* getMembers( void ) ;
        friend class openbus::Openbus ;
    } ;

    class ISessionService {
      public:
        ISessionService( void ) ;
        ~ISessionService( void ) ;
        bool createSession \
            ( scs::core::IComponent* member, ISession*& outSession, char*& outMemberIdentifier ) ;
        ISession* getSession( void ) ;
        friend class openbus::Openbus ;
    } ;
  }
}

#endif
