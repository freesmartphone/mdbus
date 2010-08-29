AC_INIT([fsodatad], [0.1.0], [smartphones-userland@linuxtogo.org], [fsodatad])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

VALA_REQUIRED=0.9.6.1
GLIB_REQUIRED=2.18.0
GEE_REQUIRED=0.5.0
XML_REQUIRED=2.7.3
DBUS_REQUIRED=1.2.1
DBUS_GLIB_REQUIRED=0.76
FSO_GLIB_REQUIRED=2010.05.11.2
FSO_REQUIRED=0.2.3
MBPI_REQUIRED=20090918

# vala
PKG_CHECK_MODULES(VALA,
  vala-0.10 >= $VALA_REQUIRED)

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

# gee
PKG_CHECK_MODULES(GEE,
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)

# xml
PKG_CHECK_MODULES(XML,
  libxml-2.0 >= $XML_REQUIRED)
AC_SUBST(XML_CFLAGS)
AC_SUBST(XML_LIBS)

# dbus and dbus-glib
PKG_CHECK_MODULES(DBUS,
  dbus-1 >= $DBUS_REQUIRED
  dbus-glib-1 >= $DBUS_GLIB_REQUIRED)
AC_SUBST(DBUS_CFLAGS)
AC_SUBST(DBUS_LIBS)

# dbus conf directory
DBUS_DIR="`$PKG_CONFIG --variable=sysconfdir dbus-1`"
if (test -z "{DBUS_DIR}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="$DBUS_DIR/dbus-1"
fi
AC_SUBST(DBUS_DIR)

# dbus service directory
DBUS_SERVICE_DIR="`$PKG_CONFIG --variable=session_bus_services_dir dbus-1`"
if (test -z "{DBUS_SERVICE_DIR}"); then
  DBUS_SERVICE_DIR="${datadir}/dbus-1/services"
fi
AC_SUBST(DBUS_SERVICE_DIR)

# framework
PKG_CHECK_MODULES(FSO,
  fsoframework-2.0 >= $FSO_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

# fso-glib
PKG_CHECK_MODULES(FSO_GLIB,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED)

# check for debugging
AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [debug=$enableval],
  [debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$debug" = x"yes"])

# git version
GITV=`cat ../.git/refs/heads/master || echo "unknown"`
AC_DEFINE_UNQUOTED([PACKAGE_GITV], ["${GITV}"], [git version])

# mobile broadband provider info database
PKG_CHECK_MODULES(MBPI,
  mobile-broadband-provider-info >= $MBPI_REQUIRED)
MBPI_DATABASE="`$PKG_CONFIG --variable=database mobile-broadband-provider-info`"
if (test -z "{MPBI_DATABASE}"); then
  AC_ERROR([Can not find mobile broadband provider info database file])
fi
AC_SUBST(MBPI_DATABASE)
AC_DEFINE_UNQUOTED([MBPI_DATABASE_PATH], ["${MBPI_DATABASE}"], [Path to xml service provider file])

# datadir
if test "x$prefix" != "xNONE"; then
  pkgdatadir='${prefix}/share/fsodatad'
else
  pkgdatadir='/usr/local/share/fsodatad'
fi
eval PACKAGE_DATADIR="${pkgdatadir}"
AC_DEFINE_UNQUOTED([PACKAGE_DATADIR], ["${PACKAGE_DATADIR}"], [Shared data directory])

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
#
# Info
#
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
