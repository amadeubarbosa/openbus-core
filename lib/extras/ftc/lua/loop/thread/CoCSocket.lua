--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.2 alpha                                                         --
-- Title  : Lua Socket Wrapper for Cooperative Scheduling                     --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
-- Date   : 05/03/2006 20:43                                                  --
--------------------------------------------------------------------------------

--[[VERBOSE]] local verbose = require("loop.thread.Scheduler").verbose

local assert = assert
local type   = type

local coroutine = require "coroutine"

local print = print
local receiveC     = receiveC
local sendC        = sendC

local oo           = require "loop.simple"
local CoSocket     = require "loop.thread.CoSocket"

module "loop.thread.CoCSocket"

oo.class(_M, CoSocket)

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

function __index(self, field)
  return _M[field] or CoSocket.__index(self, field)
end

--------------------------------------------------------------------------------
-- Wrapping functions ----------------------------------------------------------
--------------------------------------------------------------------------------

local function wrappedreceiveC(self, nbytes, userdata)
--[[VERBOSE]] verbose:cosocket(true, "performing wrapped receive")
  local socket    = self.__object
  local timeout   = self.timeout
  local readlocks = self.cosocket.readlocks
  local scheduler = self.cosocket.scheduler
  local current   = scheduler:checkcurrent()

  assert(socket, "bad argument #1 to `receive' (wrapped socket expected)")
  assert(readlocks[socket] == nil, "attempt to read a socket in use")

  -- get data already avaliable
  local result, errmsg, partial = receiveC(socket, nbytes, userdata, 0)

  -- check if job has completed
  if not result and errmsg == "timeout" and timeout ~= 0 then
--[[VERBOSE]] verbose:cosocket(true,"waiting for remaining of results")
    local running = scheduler.running
    local sleeping = scheduler.sleeping
    local reading = scheduler.reading

    -- set to be waken at timeout, if specified
    if timeout and timeout > 0 then
      sleeping:enqueue(current, scheduler:time() + timeout)
--[[VERBOSE]] verbose:threads(current,"registered for signal in ",timeout," seconds")
    end

    -- lock socket to avoid use by other coroutines
    readlocks[socket] = true

    -- block current thread on the socket
    reading:add(socket, current)
--[[VERBOSE]] verbose:threads(current,"subscribed for read signal")

    -- reduce the number of required bytes
    if type(nbytes) == "number" then
      nbytes = nbytes - partial
--[[VERBOSE]] verbose:cosocket("amountof required bytes reduced to ",pattern)
    end

    local newdata = partial
    repeat
      -- stop current thread
      running:remove(current, self.currentkey)
--[[VERBOSE]] verbose:threads(current,"suspended")
      coroutine.yield()
--[[VERBOSE]] verbose:cosocket(false,"wrapped receive resumed")

      -- check if the socket is ready
      if reading[socket] == current then
        reading:remove(socket)
--[[VERBOSE]] verbose:threads(current,"unsubscribed for read signal")
        errmsg = "timeout"
--[[VERBOSE]] verbose:cosocket(false,"wrapped send timed out")
      else
--[[VERBOSE]] verbose:cosocket "readingmore data from socket"
        result, errmsg, newdata = receiveC(socket, nbytes, userdata, partial)
        partial = partial + newdata
        if result then
--[[VERBOSE]] verbose:cosocket "receivedall requested data"
--[[VERBOSE]] verbose:cosocket(false,"returning results after waiting")
        else
--[[VERBOSE]] verbose:cosocket "receivedonly partial data"

          if errmsg == "timeout" then
            -- block current thread on the socket for more data
            reading:add(socket, current)
--[[VERBOSE]] verbose:threads(current,"subscribed for another read signal")

            -- reduce the number of required bytes
            if type(nbytes) == "number" then
              nbytes = nbytes - newdata
--[[VERBOSE]] verbose:cosocket("amountof required bytes reduced to ",pattern)
            end

            -- cancel error message
            errmsg = nil
--[[VERBOSE]] else verbose:cosocket(false, "returning error ",errmsg," after waiting")
          end
        end
      end
    until result or errmsg

    -- remove from sleeping queue if it was waken because of data on socket.
    if timeout and timeout > 0 and errmsg ~= "timeout" then
      sleeping:remove(current)
--[[VERBOSE]] verbose:threads(current,"removed from sleeping queue")
    end

    -- unlock socket to allow use by other coroutines
    readlocks[socket] = nil
--[[VERBOSE]] else verbose:cosocket(false, "returning results without waiting")
  end

  return result, errmsg, partial
end

local function wrappedsendC(self, nbytes, userdata)
--[[VERBOSE]] verbose:cosocket(true,"performing wrapped send")
  local socket     = self.__object
  local timeout    = self.timeout
  local writelocks = self.cosocket.writelocks
  local scheduler  = self.cosocket.scheduler
  local current    = scheduler:checkcurrent()

  assert(socket, "bad argument #1 to `send' (wrapped socket expected)")
  assert(writelocks[socket] == nil, "attempt to write a socket in use")

  -- fill buffer space already avaliable
  local sent, errmsg, lastbyte = sendC(socket, nbytes, userdata, 0)
--print('NBYTES',nbytes,'SENT',sent,'ERRMSG', errmsg,'LASTBYTE', lastbyte)
  -- check if job has completed
  if not sent and errmsg == "timeout" and timeout ~= 0 then
--[[VERBOSE]] verbose:cosocket(true,"waiting to send remaining data")
    local running = scheduler.running
    local sleeping = scheduler.sleeping
    local writing = scheduler.writing

    -- set to be waken at timeout, if specified
    if timeout and timeout > 0 then
      sleeping:enqueue(current, scheduler:time() + timeout)
--[[VERBOSE]] verbose:threads(current,"registered for signal in ",timeout," seconds")
    end

    -- lock socket to avoid use by other coroutines
    writelocks[socket] = true

    -- block current thread on the socket
    writing:add(socket, current)
--[[VERBOSE]] verbose:threads(current,"subscribed for write signal")

    repeat
      -- stop current thread
      running:remove(current, self.currentkey)
--[[VERBOSE]] verbose:threads(current,"suspended")
      coroutine.yield()
--[[VERBOSE]] verbose:cosocket "wrappedsend resumed"

      -- check if the socket is ready
      if writing[socket] == current then
        writing:remove(socket)
--[[VERBOSE]] verbose:threads(current,"unsubscribed for write signal")
        errmsg = "timeout"
--[[VERBOSE]] verbose:cosocket "wrappedsend timed out"
      else
        nbytes = nbytes - lastbyte
--[[VERBOSE]] verbose:cosocket "writing remaining data into socket"
--print(lastbyte+1)
        sent, errmsg, lastbyte = sendC(socket, nbytes, userdata, lastbyte+1)
--print('NBYTES',nbytes,'SENT',sent,'ERRMSG', errmsg,'LASTBYTE', lastbyte)
        if not sent and errmsg == "timeout" then
          -- block current thread on the socket to write data
          writing:add(socket, current)
--[[VERBOSE]] verbose:threads(current,"subscribed for another write signal")
          -- cancel error message
          errmsg = nil
--[[VERBOSE]] elseif sent then verbose:cosocket "sent all supplied data" else verbose:cosocket("returning error \
",errmsg," after waiting")
        end
      end
    until sent or errmsg

    -- remove from sleeping queue, if it was waken because of data on socket.
    if timeout and timeout > 0 and errmsg ~= "timeout" then
      sleeping:remove(current)
--[[VERBOSE]] verbose:threads(current,"removed from sleeping queue")
    end

    -- unlock socket to allow use by other coroutines
    writelocks[socket] = nil
--[[VERBOSE]] verbose:cosocket "send done after waiting" else verbose:cosocket(false, "send done without waiting")
  end

  return sent, errmsg, lastbyte
end

function wrap(self, socket, ...)
--[[VERBOSE]] verbose:cosocket "newwrapped socket"
  if socket then
    socket = CoSocket.wrap(self, socket)
    socket.sendC    = wrappedsendC
    socket.receiveC = wrappedreceiveC
  end
  return socket, ...
end
