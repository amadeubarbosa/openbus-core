#
# makefile
#

TECMAKE=tecmake

all: server client

server: server.cpp
	${TECMAKE} MF=server

client: client.cpp
	${TECMAKE} MF=client

clean:
	${TECMAKE} MF=server clean
	${TECMAKE} MF=client clean
