include src/config.mak

all:
	@(cd src; tecmake)
	@(cd ${TARGETROOT}/${TEC_UNAME}; mkdir -p liboil; cd liboil; \
		ln -sf ../liboilbit.so bit.so)
	@mkdir -p ${TARGETROOT}/lua
	@(tar czvf oil.tar.gz `find lua -name '*.lua' -mindepth 2`; \
		tar xzvf oil.tar.gz -C ${TARGETROOT}; \
		rm oil.tar.gz)

clean:
	@(cd src; tecmake clean)
