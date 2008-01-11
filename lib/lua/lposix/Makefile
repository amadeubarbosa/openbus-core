SHELL := bash

all:
	@(cd src; tecmake ; \
      if ! test -L ${OPENBUS_HOME}/include/lposix.h; then \
        echo "Criando link para arquivo de include..." ; \
        ln -s ${PWD}/src/lposix.h ${OPENBUS_HOME}/include/ ; \
      fi)

clean:
	@(cd src; tecmake clean-all)
