local _G = require "_G"
local pairs = _G.pairs

local os = require "os"
local date = os.date

local cothread = require "cothread"
local time = cothread.now

local oo = require "openbus.util.oo"
local class = oo.class


local modes = {
  AngryDog = function (self, now, before)
    local wait = self.period-(now-before.time)
    if wait > 0 then
      return wait
    end
  end,
  LeakyBucket = function (self, now, before)
    local rate = self.limit/self.period
    count = count - (now-before.time)*rate -- leak the bucket
    before.time = now
    if count > 0 then
      before.count = count
      return 1/rate
    end
  end,
}

local PasswordAttempts = class{
  modes = modes,
  mode = modes.AngryDog,
}

function PasswordAttempts:__init()
  self.attemptsOf = {}
end

function PasswordAttempts:allow(sourceid)
  local attemptsOf = self.attemptsOf
  local attempts = attemptsOf[sourceid]
  if attempts ~= nil then
    local blocked = self:mode(time(), attempts)
    if blocked == nil then
      attemptsOf[sourceid] = nil
    else
      if attempts.count >= self.limit then
        return false, wait
      end
    end
  end
  return true
end

function PasswordAttempts:denied(sourceid)
  if self.period > 0 then
    local now = self:clean()
    local attemptsOf = self.attemptsOf
    local attempts = attemptsOf[sourceid]
    if attempts == nil then
      attempts = { time = now, count = 1}
      attemptsOf[sourceid] = attempts
    else
      attempts.time = now
      attempts.count = attempts.count + 1
    end
  end
end

function PasswordAttempts:granted(sourceid)
  self.attemptsOf[sourceid] = nil
end

function PasswordAttempts:clean()
  local now = time()
  local attemptsOf = self.attemptsOf
  for sourceid, attempts in pairs(attemptsOf) do
    local count = self:mode(now, attempts.time, attempts.count)
    if count == nil then
      attemptsOf[sourceid] = nil
    else
      attempts.count = count
    end
  end
  return now
end

return PasswordAttempts