SHELL := bash

all:
	@(cd src; tecmake ; \
      if ! test -L ${OPENBUS_HOME}/include/luuid.h; then \
        echo "Criando link para arquivo de include..." ; \
        ln -s ${PWD}/src/luuid.h ${OPENBUS_HOME}/include/ ; \
      fi)

clean:
	@(cd src; tecmake clean)
