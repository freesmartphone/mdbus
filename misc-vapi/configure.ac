AC_INIT([misc-vapi], [0.5.0], [smartphones-userland@linuxtogo.org], [misc-vapi])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

#
# pkg-config requirements
#
PKG_PROG_PKG_CONFIG
VALA_REQUIRED=0.7.3
GLIB_REQUIRED=2.18.0

# vala
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
PKG_CHECK_MODULES(VALA,
  vala-1.0 >= $VALA_REQUIRED)

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)



# shall we compile the tests? [default=yes]
AC_ARG_ENABLE(tests,      [  --disable-tests      skip building the tests [[default=no]]])
AM_CONDITIONAL(MAKE_TESTS, test x$enable_tests != xno)
AC_MSG_CHECKING([whether to compile the tests])
if test "$enable_tests" != no; then
  AC_MSG_RESULT(yes)
else
  AC_MSG_RESULT(no)
fi
    

#
# output
#
AC_CONFIG_FILES([Makefile
  tests/Makefile
  vapi/Makefile])

AC_OUTPUT
