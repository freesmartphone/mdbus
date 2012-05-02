m4_define([fsobasics_released], [0])
m4_define([fsobasics_base_version], [0.11.0])
m4_define([fsobasics_maybe_gitrev], m4_if(fsobasics_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsobasics_version], m4_if(fsobasics_released, [1], [fsobasics_base_version], [fsobasics_base_version-fsobasics_maybe_gitrev]))

AC_INIT([libfsobasics], [fsobasics_version], [smartphones-userland@linuxtogo.org], [libfsobasics])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREREQ([2.65])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2 no-dist-gzip])
AM_MAINTAINER_MODE([enable])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL
PKG_PROG_PKG_CONFIG([0.21])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

#########################################################################################
# Vala building options -- allows tarball builds without installing vala
#########################################################################################

VALA_REQUIRED=0.14.2

AC_ARG_ENABLE([vala], AS_HELP_STRING([--enable-vala],[Enable building from Vala sources]),
              [enable_vala=$enableval], [enable_vala=no])

# Force Vala for non-release builds
m4_if(fsobasics_released, [1], [],
      [
        enable_vala=yes
        echo "Vala compiler required for non-release builds; requiring Vala..."
      ])

if test "x$enable_vala" = "xyes" ; then
    AM_PROG_VALAC([$VALA_REQUIRED])
    if test "x$VALAC" = "x" ; then
        AC_MSG_ERROR([Vala requested but valac is not installed])
    fi
fi

AM_CONDITIONAL([HAVE_VALA], [test "x$enable_vala" = "xyes"])

#########################################################################################
# Check for various dependencies
#########################################################################################

GLIB_REQUIRED=2.26.0
LIBNL_REQUIRED=2.0

PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
  gthread-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(LIBNL,
  libnl-2.0 >= $LIBNL_REQUIRED)
AC_SUBST(LIBNL_CFLAGS)
AC_SUBST(LIBNL_LIBS)

#########################################################################################
# check for backtrace
#########################################################################################

AC_MSG_NOTICE([Checking whether this C library has support for backtraces...])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([#include <execinfo.h>
  void test() { backtrace( 0, 0 ); } ])], [backtrace="yes"], [backtrace="no"] )
AM_CONDITIONAL( [HAVE_BACKTRACE], [test x"$backtrace" = x"yes"])

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [enable_debug=$enableval],
  [enable_debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$enable_debug" = x"yes"])

#########################################################################################
# output
#########################################################################################

AC_CONFIG_FILES([Makefile
  fsobasics-2.0.pc
  fsobasics/Makefile
  tests/Makefile])
AC_OUTPUT

#########################################################################################
# info
#########################################################################################

echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options:"
echo
echo "  backtrace support.......: $backtrace"
echo
echo "  debug build.............: $enable_debug"
echo
echo "  prefix..................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
