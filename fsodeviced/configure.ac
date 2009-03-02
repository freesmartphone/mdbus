AC_INIT([fsodeviced], [0.0.0.0], [smartphones-userland@linuxtogo.org], [fsodeviced])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.18.0
FSO_REQUIRED=0.0.0.0

PKG_CHECK_MODULES(DEPS,
  fsoframework-2.0 >= $FSO_REQUIRED
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(DEPS_CFLAGS)
AC_SUBST(DEPS_LIBS)

AC_CONFIG_FILES([
  Makefile
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  tests/Makefile
])

AC_OUTPUT
