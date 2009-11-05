AC_INIT([libfsoresource], [0.1.1], [smartphones-userland@linuxtogo.org], [libfsoresource])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_PROG_LIBTOOL

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

#
# pkg-config requirements
#
PKG_PROG_PKG_CONFIG

VALA_REQUIRED=0.7.8
GLIB_REQUIRED=2.18.0
FSO_BASICS_REQUIRED=0.8.9.9
FSO_FRAMEWORK_REQUIRED=0.2.3.1
FSO_GLIB_REQUIRED=0.2.0

# vala
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
PKG_CHECK_MODULES(VALA,
  vala-1.0 >= $VALA_REQUIRED)

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
  fsobasics-2.0 >= $FSO_BASICS_REQUIRED
  fsoframework-2.0 >= $FSO_FRAMEWORK_REQUIRED
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

#
# output
#
AC_CONFIG_FILES([Makefile
  fsoresource-2.0.pc
  fsoresource/Makefile
  tests/Makefile])

AC_OUTPUT

#
# Info
#
echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION"
echo "------------------------------------------------------------------------"
echo
echo "  Compilation...............: make"
echo
echo "  Installation..............: make install"
echo
echo "    prefix..................: $prefix"
echo
