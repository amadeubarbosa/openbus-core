--
-- openbus.lua
--

package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"

--OIL_FLAVOR="corba;typed;base"

require 'oil'

oilcorbaidlstring = oil.corba.idl.string

oil.loadidlfile( os.getenv( "CORBA_IDL_DIR" ).."/access_control_service.idl" )
oil.loadidlfile( os.getenv( "CORBA_IDL_DIR" ).."/registry_service.idl" )
oil.loadidlfile( os.getenv( "CORBA_IDL_DIR" ).."/session_service.idl" )

--temp
oil.loadidl [[ interface hello { void say_hello() ; }; ]]

local lir = oil.getLIR()

IComponent = require 'scs.core.IComponent'

oil.verbose:level(3)
oil.tasks.verbose:level(0)
--oil.tasks.verbose:flag("threads", true)

-- Metodo utilizado pelo interceptador do OiL
function sendrequest(credential, credentialType, contextID, request)
  local encoder = oil.newencoder()
  encoder:put(credential, lir:lookup_id(credentialType).type)
  request.service_context =  {
     { context_id = contextID, context_data = encoder:getdata() }
   }
end

oil.tasks:register(coroutine.create(oil.run))

-- Invoke with concurrency
function invoke( func, ... )
  local res
  oil.main ( function()
    res = { oil.pcall( func, unpack( arg ) ) }
    oil.tasks:halt()
  end )
  if ( not res[ 1 ] ) then
    error( res[ 2 ] )
  end --if
  return select( 2, unpack( res ) )
end

-- dumping function
function dump(tab)
print('## DUMPING ->', tab)
for k,v in pairs(tab) do print(k,v) end
return tab
end