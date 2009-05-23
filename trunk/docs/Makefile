doc:
	@(cd idl; doxygen openbus.dox)
	@(mkdir -p lua; cd ..; luadoc --nofiles -d docs/lua `find core/services -name '*.lua'`)
