# makefile for uuid library for Lua

# change these to reflect your Lua installation
#LUA_HOME= /usr/local
# System's libraries directory (where binary libraries are installed)
LUA_LIBDIR= ${LUA_HOME}/lib/lua/5.1
LUAINC= $(LUA_HOME)/include
LUALIB= $(LUA_HOME)/lib
LUABIN= $(LUA_HOME)/bin

# no need to change anything below here
CFLAGS= $(INCS) $(WARN) -O2 $G
WARN= -ansi -pedantic -Wall
INCS= -I$(LUAINC)

MYNAME= uuid
MYLIB= l$(MYNAME)
T= $(MYLIB).so
OBJS= $(MYLIB).o
TEST= test.lua

all:	$T

test:	$T
	$(LUABIN)/lua -l$(MYNAME) $(TEST)

o:	$(MYLIB).o

so:	$T

$T:	$(OBJS)
	$(CC) -o $@ -shared $(OBJS) -luuid

clean:
	rm -f $(OBJS) $T core core.* a.out

doc:
	@echo "$(MYNAME) library:"
	@fgrep '/**' $(MYLIB).c | cut -f2 -d/ | tr -d '*' | sort | column

# distribution

FTP= $(HOME)/public/ftp/lua
D= $(MYNAME)
A= $(MYLIB).tar.gz
TOTAR= Makefile,README,$(MYLIB).c,$(MYNAME).lua,test.lua

tar:	clean
	tar zcvf $A -C .. $D/{$(TOTAR)}

distr:	tar
	touch -r $A .stamp
	mv $A $(FTP)

diff:	clean
	tar zxf $(FTP)/$A
	diff $D .

install: $T
	mkdir -p $(LUA_LIBDIR)
	cp $T $(LUA_LIBDIR)

# eof
