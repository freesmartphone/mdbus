m4_define([fsotest_released], [0])
m4_define([fsotest_base_version], [0.11.0])
m4_define([fsotest_maybe_gitrev], m4_if(fsotest_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsotest_version], m4_if(fsotest_released, [1], [fsotest_base_version], [fsotest_base_version-fsotest_maybe_gitrev]))

AC_INIT([fsotest], fsotest_version, [smartphones-userland@linuxtogo.org], [fsotest])
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
m4_if(fsotest_released, [1], [],
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
FSO_REQUIRED=0.11.0
FSO_GLIB_REQUIRED=2012.05.24.1

PKG_CHECK_MODULES(GLIB, glib-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(FSO,
	fsotest-2.0 >= $FSO_REQUIRED
	fsobasics-2.0 >= $FSO_REQUIRED
	fsoframework-2.0 >= $FSO_REQUIRED
	fsoresource-2.0 >= $FSO_REQUIRED
	fsosystem-2.0 >= $FSO_REQUIRED
	fso-glib-1.0 >= $FSO_GLIB_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

#########################################################################################
# dbus conf directory
#########################################################################################

AC_ARG_WITH(dbusconfdir, AC_HELP_STRING([--with-dbusconfdir=PATH], [path to D-Bus config directory]),
			[path_dbusconf=${withval}], [path_dbusconf="`$PKG_CONFIG --variable=sysconfdir dbus-1`"])

if (test -z "${path_dbusconf}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="${path_dbusconf}/dbus-1"
fi
AC_SUBST(DBUS_DIR)
AC_DEFINE_UNQUOTED([DBUS_SERVICE_DIR], ["${DBUS_SERVICE_DIR}"], [dbus service activation dir])

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [enable_debug=$enableval],
  [enable_debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$enable_debug" = x"yes"])

#########################################################################################
# data files
#########################################################################################

AC_ARG_ENABLE(datafiles, AC_HELP_STRING([--disable-datafiles],
			[don't install configuration and data files]),
					[enable_datafiles=${enableval}])
AM_CONDITIONAL(WANT_DATAFILES, test "${enable_datafiles}" != "no")

#########################################################################################
# output
#########################################################################################

AC_OUTPUT([
	Makefile
	conf/Makefile
	conf/default/Makefile
	data/Makefile
	api/Makefile
	system/Makefile
])

#########################################################################################
# info
#########################################################################################

echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE $VERSION"
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
