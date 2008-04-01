local require = require
local builder = require "oil.builder"
local arch    = require "oil.arch.cooperative"

module "oil.builder.csockets"

TaskManager = arch.TaskManager{
	require "loop.thread.SocketScheduler",
	sockets = require "loop.thread.CoCSocket",
}

function create(comps)
	return builder.create(_M, comps)
end

