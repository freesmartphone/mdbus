AC_INIT([libfsoframework], [0.8.2], [smartphones-userland@linuxtogo.org], [libfsoframework])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

# pkg-config requirements
PKG_PROG_PKG_CONFIG
VALA_REQUIRED=0.9.6.1
DBUS_REQUIRED=1.2.1
DBUS_GLIB_REQUIRED=0.76
GLIB_REQUIRED=2.18.0
FSO_BASICS_REQUIRED=0.9.9

# vala
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
PKG_CHECK_MODULES(VALA,
  vala-0.10 >= $VALA_REQUIRED)

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

# dbus and dbus-glib
PKG_CHECK_MODULES(DBUS,
  dbus-1 >= $DBUS_REQUIRED
  dbus-glib-1 >= $DBUS_GLIB_REQUIRED)
AC_SUBST(DBUS_CFLAGS)
AC_SUBST(DBUS_LIBS)

# libfsobasics
PKG_CHECK_MODULES(FSOBASICS,
  fsobasics-2.0 >= $FSO_BASICS_REQUIRED)
AC_SUBST(FSOBASICS_CFLAGS)
AC_SUBST(FSOBASICS_LIBS)

# gather libdir
if test "x$prefix" != "xNONE"; then
  pkglibdir='${prefix}/lib/cornucopia'
else
  pkglibdir='/usr/local/lib/cornucopia'
fi
eval PACKAGE_LIBDIR="${pkglibdir}"
AC_DEFINE_UNQUOTED([PACKAGE_LIBDIR], ["${PACKAGE_LIBDIR}"], [Module directory])

# check for debugging
AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [debug=$enableval],
  [debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$debug" = x"yes"])

# git version
GITV=`cat ../.git/refs/heads/master || echo "unknown"`
AC_DEFINE_UNQUOTED([PACKAGE_GITV], ["${GITV}"], [git version])

# output
AC_CONFIG_FILES([Makefile
  fsoframework-2.0.pc
  fsoframework/Makefile
  tests/Makefile])

AC_OUTPUT

# info
echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION-$GITV"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options:"
echo
echo "  modules directory.......: $pkglibdir"
echo
echo "  debug build.............: $debug"
echo
echo "  prefix..................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
