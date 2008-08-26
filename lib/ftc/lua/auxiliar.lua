--
--  auxiliar.lua
--

require "oil"
oil.orb = oil.init {flavor = "intercepted;corba;csockets;typed;cooperative;base"}
local orb = oil.orb

require "ftc"

if not oil.isrunning then
  oil.isrunning = true
  oil.tasks:register(coroutine.create(function() return orb:run() end))
end

-- Invoke with concurrency
function invoke( func, ... )
  local res
  oil.main ( function()
    res = { oil.pcall( func, unpack( arg ) ) }
    oil.tasks:halt()
  end )
  if ( not res[ 1 ] ) then
    error( res[ 2 ] )
  end
  return select( 2, unpack( res ) )
end

