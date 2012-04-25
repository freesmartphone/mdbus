m4_define([fsodatad_released], [0])
m4_define([fsodatad_base_version], [0.11.0])
m4_define([fsodatad_maybe_gitrev], m4_if(fsodatad_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsodatad_version], m4_if(fsodatad_released, [1], [fsodatad_base_version], [fsodatad_base_version-fsodatad_maybe_gitrev]))

AC_INIT([fsodatad], fsodatad_version, [smartphones-userland@linuxtogo.org], [fsodatad])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREREQ([2.65])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2 no-dist-gzip])
AM_MAINTAINER_MODE([enable])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CC_C99
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
XML_REQUIRED=2.7.3
FSO_GLIB_REQUIRED=2012.04.18.1
FSO_REQUIRED=0.10.0
MBPI_REQUIRED=20090918

PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(GEE,
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)

PKG_CHECK_MODULES(XML,
  libxml-2.0 >= $XML_REQUIRED)
AC_SUBST(XML_CFLAGS)
AC_SUBST(XML_LIBS)

PKG_CHECK_MODULES(FSO,
  fsoframework-2.0 >= $FSO_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

PKG_CHECK_MODULES(FSO_GLIB,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED)

PKG_CHECK_MODULES(MBPI,
  mobile-broadband-provider-info >= $MBPI_REQUIRED)
MBPI_DATABASE="`$PKG_CONFIG --variable=database mobile-broadband-provider-info`"
if (test -z "{MPBI_DATABASE}"); then
  AC_ERROR([Can not find mobile broadband provider info database file])
fi
AC_SUBST(MBPI_DATABASE)
AC_DEFINE_UNQUOTED([MBPI_DATABASE_PATH], ["${MBPI_DATABASE}"], [Path to xml service provider file])

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [enable_debug=$enableval],
  [enable_debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$enable_debug" = x"yes"])

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

#########################################################################################
# dbus service directory
#########################################################################################

AC_ARG_WITH(dbusservicedir, AC_HELP_STRING([--with-dbusdatadir=PATH], [path to D-Bus data directory]),
			[path_dbusdata=${withval}], [path_dbusdata="`$PKG_CONFIG --variable=datadir dbus-1`"])

if (test -z "${path_dbusdata}"); then
	DBUS_SERVICE_DIR="${datadir}/dbus-1/system-services"
else
	DBUS_SERVICE_DIR="${path_dbusdata}/dbus-1/system-services"
fi
AC_SUBST(DBUS_SERVICE_DIR)

#########################################################################################
# datadir
#########################################################################################

if test "x$prefix" != "xNONE"; then
  pkgdatadir='${prefix}/share/fsodatad'
else
  pkgdatadir='/usr/local/share/fsodatad'
fi
eval PACKAGE_DATADIR="${pkgdatadir}"
AC_DEFINE_UNQUOTED([PACKAGE_DATADIR], ["${PACKAGE_DATADIR}"], [Shared data directory])

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

AC_CONFIG_FILES([
  Makefile
  conf/Makefile
  conf/default/Makefile
  data/Makefile
  data/org.freesmartphone.odatad.service
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/plugins/Makefile
  src/plugins/world/Makefile
  tests/Makefile
])
AC_OUTPUT

#########################################################################################
# Info
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
