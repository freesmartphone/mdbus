m4_define([mdbus_released], [1])
m4_define([mdbus_base_version], [2.3.0])
m4_define([mdbus_maybe_gitrev], m4_if(mdbus_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([mdbus_version], m4_if(mdbus_released, [1], [mdbus_base_version], [mdbus_base_version-mdbus_maybe_gitrev]))

AC_INIT([mdbus2], mdbus_version, [smartphones-userland@linuxtogo.org], [mdbus2])
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

#########################################################################################
# Vala building options -- allows tarball builds without installing vala
#########################################################################################

VALA_REQUIRED=0.14.2

AC_ARG_ENABLE([vala], AS_HELP_STRING([--enable-vala],[Enable building from Vala sources]),
              [enable_vala=$enableval], [enable_vala=no])

# Force Vala for non-release builds
m4_if(mdbus_released, [1], [],
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

AC_CHECK_LIB(readline, rl_bind_key,
             [LIBREADLINE=-lreadline
              AC_DEFINE(HAVE_LIBREADLINE, 1,
               [Define to one if you have -lreadline])],
             [LIBREADLINE=], "$LIBTERMCAP")
AC_SUBST(LIBREADLINE)
AC_SUBST(LIBTERMCAP)

AC_CHECK_LIB(history, add_history,
             [LIBHISTORY=-lhistory
              AC_DEFINE(HAVE_LIBHISTORY, 1,
               [Define to one if you have -lhistory])],
             [LIBHISTORY=])

if test -z "$LIBHISTORY" && test -n "$LIBREADLINE"; then
  AC_CHECK_LIB(readline, add_history,
               [LIBHISTORY=-lreadline
                AC_DEFINE(HAVE_LIBHISTORY, 1,
                     [Define to one if you have -lhistory])],
               [LIBHISTORY=])
fi

AC_SUBST(LIBHISTORY)

if test -z "$LIBHISTORY" && test -z "$LIBREADLINE"; then
    AC_ERROR( [Can not find readline support. Please install the development package for readline.] )
fi

PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [debug=$enableval],
  [debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$debug" = x"yes"])

AC_ARG_ENABLE(bash_completion,
  [  --enable-bash-completion    Install bash completion skript (default=disabled)],
  [bash_completion=$enableval],
  [bash_completion="no"])
AM_CONDITIONAL( [WANT_BC], [test x"$bash_completion" = x"yes"])

#########################################################################################
# output
#########################################################################################

AC_CONFIG_FILES([
  Makefile
  src/Makefile
  data/Makefile
])
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
echo "  debug build.............: $debug"
echo
echo "  prefix..................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
