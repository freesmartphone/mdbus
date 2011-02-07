AC_INIT([mdbus], [2.0.2], [smartphones-userland@linuxtogo.org], [mdbus])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

VALA_REQUIRED=0.14.0
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
m4_ifdef([AM_PROG_VALAC], [AM_PROG_VALAC([$VALA_REQUIRED])])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

# requirements
GLIB_REQUIRED=2.26.0
DBUS_REQUIRED=1.2.1

# libreadline and/or libhistory
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

# If libhistory does not provide add_history check if libreadline has it.
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

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

# check for debugging
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

# output
AC_CONFIG_FILES([
  Makefile
  src/Makefile
  data/Makefile
])
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
echo "  debug build.............: $debug"
echo
echo "  prefix..................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
