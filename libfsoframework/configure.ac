m4_define([fsoframework_released], [0])
m4_define([fsoframework_base_version], [0.12.0])
m4_define([fsoframework_maybe_gitrev], m4_if(fsoframework_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsoframework_version], m4_if(fsoframework_released, [1], [fsoframework_base_version], [fsoframework_base_version-fsoframework_maybe_gitrev]))

#  NOTE: We are using the same ABI version for all our libraries for as this make things
#  easier. Maybe we will change that later.

# If library source has changed since last release, increment revision
# If public symbols have been added, removed or changed since last release,
#  increment current and set revision to 0
# If public symbols have been added since last release, increment age
# If public symbols have been removed since last release, set age to 0
m4_define([fsoframework_lt_current], [3])
m4_define([fsoframework_lt_revision], [0])
m4_define([fsoframework_lt_age], [0])

AC_INIT([libfsoframework], fsoframework_version, [smartphones-userland@linuxtogo.org], [libfsoframework])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREREQ([2.65])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2 no-dist-gzip tar-ustar])
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

LT_CURRENT=fsoframework_lt_current
LT_REVISION=fsoframework_lt_revision
LT_AGE=fsoframework_lt_age
AC_SUBST([LT_CURRENT])
AC_SUBST([LT_REVISION])
AC_SUBST([LT_AGE])

#########################################################################################
# Vala building options -- allows tarball builds without installing vala
#########################################################################################

VALA_REQUIRED=0.16.0

AC_ARG_ENABLE([vala], AS_HELP_STRING([--enable-vala],[Enable building from Vala sources]),
              [enable_vala=$enableval], [enable_vala=no])

# Force Vala for non-release builds
m4_if(fsoframework_released, [1], [],
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
GEE_REQUIRED=0.5.0
FSO_REQUIRED=0.11.0
LIBNL_REQUIRED=3.2
GSM0710_REQUIRED=1.2.0
FSO_GLIB_REQUIRED=2012.06.06.01

PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
  gthread-2.0 >= $GLIB_REQUIRED
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(FSO_GLIB,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED)
AC_SUBST(FSO_GLIB_CFLAGS)
AC_SUBST(FSO_GLIB_LIBS)

PKG_CHECK_MODULES(LIBNL,
  libnl-3.0 >= $LIBNL_REQUIRED
  libnl-route-3.0 >= $LIBNL_REQUIRED)
AC_SUBST(LIBNL_CFLAGS)
AC_SUBST(LIBNL_LIBS)

PKG_CHECK_MODULES(GSM0710,
  gsm0710-1.0 >= $GSM0710_REQUIRED)
AC_SUBST(GSM0710_CFLAGS)
AC_SUBST(GSM0710_LIBS)

#########################################################################################
# check for backtrace
#########################################################################################

AC_MSG_NOTICE([Checking whether this C library has support for backtraces...])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([#include <execinfo.h>
  void test() { backtrace( 0, 0 ); } ])], [backtrace="yes"], [backtrace="no"] )
AM_CONDITIONAL( [HAVE_BACKTRACE], [test x"$backtrace" = x"yes"])

#########################################################################################
# gather libdir
#########################################################################################

if test "x$prefix" != "xNONE"; then
  pkglibdir='${prefix}/lib/cornucopia'
else
  pkglibdir='/usr/local/lib/cornucopia'
fi
eval PACKAGE_LIBDIR="${pkglibdir}"
AC_DEFINE_UNQUOTED([PACKAGE_LIBDIR], ["${PACKAGE_LIBDIR}"], [Module directory])

#########################################################################################
# check for disabling of fast baud rates
#########################################################################################

AC_ARG_ENABLE(fast-baud,
  AS_HELP_STRING([--disable-fast-baud], [Disable fast baud rates (default=yes)]),
  [fastbaud="$enableval"],
  AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
    #include <termios.h>
    int tspeed = B2500000 + B4000000;
  ]])],fastbaud="yes",fastbaud="no") )
AM_CONDITIONAL( [FAST_BAUD], [test x"$fastbaud" = x"yes"])

#########################################################################################
# check for disabling the n_gsm support
#########################################################################################

AC_ARG_ENABLE(ngsm,
  AS_HELP_STRING([--disable-ngsm], [Disable support for the N_GSM line discipline (default=yes)]),
  [ngsm="$enableval"],
  [ngsm="yes"])
AM_CONDITIONAL( [WANT_NGSM], [test x"$ngsm" = x"yes"])

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [debug=$enableval],
  [debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$debug" = x"yes"])

#########################################################################################
# output
#########################################################################################

AC_CONFIG_FILES([
  Makefile
  vapi/Makefile
  fsosystem/fsosystem-2.0.pc
  fsosystem/Makefile
  fsobasics/fsobasics-2.0.pc
  fsobasics/Makefile
  fsotransport/fsotransport-2.0.pc
  fsotransport/Makefile
  gsm0710mux/gsm0710mux-1.0.pc
  gsm0710mux/Makefile
  fsoresource/fsoresource-2.0.pc
  fsoresource/Makefile
  fsoframework/fsoframework-2.0.pc
  fsoframework/Makefile
  fsotest/fsotest-2.0.pc
  fsotest/Makefile
  tests/Makefile
  tests/fsosystem/Makefile
  tests/fsobasics/Makefile
  tests/fsotransport/Makefile
  tests/fsoresource/Makefile
  tests/fsotest/Makefile
  tests/fsoframework/Makefile])
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
echo "  Vala....................: $enable_vala"
echo
echo "  Vala Compiler...........: ${VALAC}"
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
