#
# makefile
#

include config

all: precompile
	tecmake

precompile:
	${LUA51BIN} precompiler.lua -f auxiliar -p auxiliar openbus.lua

clean:
	tecmake clean-all

