m4_define([fsosystem_released], [0])
m4_define([fsosystem_base_version], [0.12.0])
m4_define([fsosystem_maybe_gitrev], m4_if(fsosystem_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsosystem_version], m4_if(fsosystem_released, [1], [fsosystem_base_version], [fsosystem_base_version-fsosystem_maybe_gitrev]))

# If library source has changed since last release, increment revision
# If public symbols have been added, removed or changed since last release,
#  increment current and set revision to 0
# If public symbols have been added since last release, increment age
# If public symbols have been removed since last release, set age to 0
m4_define([fsosystem_lt_current], [0])
m4_define([fsosystem_lt_revision], [0])
m4_define([fsosystem_lt_age], [0])

AC_INIT([libfsosystem], fsosystem_version, [smartphones-userland@linuxtogo.org], [libfsosystem])
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

LT_CURRENT=fsosystem_lt_current
LT_REVISION=fsosystem_lt_revision
LT_AGE=fsosystem_lt_age
AC_SUBST([LT_CURRENT])
AC_SUBST([LT_REVISION])
AC_SUBST([LT_AGE])

#########################################################################################
# Vala building options -- allows tarball builds without installing vala
#########################################################################################

VALA_REQUIRED=0.14.2

AC_ARG_ENABLE([vala], AS_HELP_STRING([--enable-vala],[Enable building from Vala sources]),
              [enable_vala=$enableval], [enable_vala=no])

# Force Vala for non-release builds
m4_if(fsosystem_released, [1], [],
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

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  AS_HELP_STRING([--enable-debug], [compile with debug code]),
  [enable_debug=$enableval], [enable_debug=no])
AM_CONDITIONAL([HAVE_DEBUG], [test "x$enable_debug" = "xyes"])

#########################################################################################
# output
#########################################################################################

AC_CONFIG_FILES([Makefile
  fsosystem-2.0.pc
  fsosystem/Makefile
  vapi/Makefile
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
echo "  Vala....................: $enable_vala"
echo
echo "  Vala Compiler...........: ${VALAC}"
echo
echo "  debug build.............: $enable_debug"
echo
echo "  prefix..................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
