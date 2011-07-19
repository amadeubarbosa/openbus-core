#
# source this file (. /usr/local/mico/mico.sh) in sh,ksh,zsh,bash to set
# up paths for MICO.
#

prefix="${OPENBUS_HOME}"
exec_prefix="${prefix}"
MICODIR="$exec_prefix"
MICOSHAREDDIR="$prefix"
MICOVERSION=` sed -n '/MICO_VERSION/ { y/b/./; s#^[^"]*"\([^"]*\)".*$#\1#p; }' \
  "$MICODIR/incpath/mico-2.3.13-singlethread/${TEC_UNAME}/mico/version.h" `
MICOBIN="$MICODIR/bin/${TEC_UNAME}/mico-${MICOVERSION}-singlethread"
PATH="$MICODIR/bin/${TEC_UNAME}/mico-${MICOVERSION}-singlethread:$PATH"
LD_LIBRARY_PATH="$MICODIR/libpath/${TEC_UNAME}/mico-${MICOVERSION}-singlethread:${LD_LIBRARY_PATH:-}"
DYLD_LIBRARY_PATH="$MICODIR/libpath/${TEC_UNAME}/mico-${MICOVERSION}-singlethread:${DYLD_LIBRARY_PATH:-}"
SHLIB_PATH="$MICODIR/libpath/${TEC_UNAME}/mico-${MICOVERSION}-singlethread:${SHLIB_PATH:-}"
LIBPATH="$MICODIR/libpath/${TEC_UNAME}/mico-${MICOVERSION}-singlethread:${LIBPATH:-}"
MANPATH="$MICOSHAREDDIR/man:${MANPATH:-}"
CPLUS_INCLUDE_PATH="$MICODIR/incpath/mico-${MICOVERSION}-singlethread/${TEC_UNAME}"
LIBRARY_PATH="$MICODIR/libpath/${TEC_UNAME}/mico-${MICOVERSION}-singlethread"

export MICOVERSION PATH LD_LIBRARY_PATH DYLD_LIBRARY_PATH MANPATH CPLUS_INCLUDE_PATH LIBRARY_PATH
export SHLIB_PATH LIBPATH MICODIR MICOBIN

unset prefix
unset exec_prefix
