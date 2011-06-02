AC_INIT([fsotdld], [0.3.1], [smartphones-userland@linuxtogo.org], [fsotdld])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

VALA_REQUIRED=0.12.0
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
m4_ifdef([AM_PROG_VALAC], [AM_PROG_VALAC([$VALA_REQUIRED])])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.26.0
GEE_REQUIRED=0.5.0
SOUP_REQUIRED=2.29
JSON_REQUIRED=0.10.2
FSO_GLIB_REQUIRED=2011.01.10.1
FSO_BASICS_REQUIRED=0.9.10
FSO_FRAMEWORK_REQUIRED=0.2.3
FSO_TRANSPORT_REQUIRED=0.9.6
FSO_RESOURCE_REQUIRED=0.1.0

##############################################################################
# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

##############################################################################
# gee
PKG_CHECK_MODULES(GEE,
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)

##############################################################################
# soup
PKG_CHECK_MODULES(SOUP,
  libsoup-2.4 >= $SOUP_REQUIRED)
AC_SUBST(SOUP_CFLAGS)
AC_SUBST(SOUP_LIBS)

##############################################################################
# json-glib
PKG_CHECK_MODULES(JSON,
  json-glib-1.0 >= $JSON_REQUIRED)
AC_SUBST(JSON_CFLAGS)
AC_SUBST(JSON_LIBS)

##############################################################################
# optional feature: gpsd
AC_ARG_ENABLE(provider-libgps,
  AS_HELP_STRING([--enable-provider-libgps], [Enable building the libgps location provider (default=disabled)]),
  [libgps=$enableval],
  [libgps="no"])

if test x$libgps = x"yes"; then
    # libgps
    PKG_CHECK_MODULES(GPS,
      libgps >= 0.0)
    AC_SUBST(GPS_CFLAGS)
    AC_SUBST(GPS_LIBS)
fi
AM_CONDITIONAL( [WANT_LIBGPS], [test x"$libgps" = x"yes"])

##############################################################################
# dbus conf directory
DBUS_DIR="`$PKG_CONFIG --variable=sysconfdir dbus-1`"
if (test -z "{DBUS_DIR}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="$DBUS_DIR/dbus-1"
fi
AC_SUBST(DBUS_DIR)

##############################################################################
# dbus service directory
DBUS_SERVICE_DIR="`$PKG_CONFIG --variable=session_bus_services_dir dbus-1`"
if (test -z "{DBUS_SERVICE_DIR}"); then
  DBUS_SERVICE_DIR="${datadir}/dbus-1/services"
fi
AC_SUBST(DBUS_SERVICE_DIR)

##############################################################################
# framework
PKG_CHECK_MODULES(FSO,
  fsobasics-2.0 >= $FSO_BASICS_REQUIRED
  fsoframework-2.0 >= $FSO_FRAMEWORK_REQUIRED
  fsotransport-2.0 >= $FSO_TRANSPORT_REQUIRED
  fsoresource-2.0  >= $FSO_RESOURCE_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

# fso-glib
PKG_CHECK_MODULES(FSO_GLIB,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED)

# git version
GITV=`cat ../.git/refs/heads/master || echo "unknown"`
AC_DEFINE_UNQUOTED([PACKAGE_GITV], ["${GITV}"], [git version])

AC_CONFIG_FILES([
  Makefile
  conf/Makefile
  conf/default/Makefile
  conf/openmoko_gta/Makefile
  conf/htc_qualcomm_dream/Makefile
  conf/htcleo/Makefile
  data/Makefile
  data/org.freesmartphone.otdld.service
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/plugins/Makefile
  src/plugins/alarm/Makefile
  src/plugins/contextmanager/Makefile
  src/plugins/provider_gps/Makefile
  src/plugins/provider_gps_nmea/Makefile
  src/plugins/provider_location_cellidwifi/Makefile
  src/plugins/provider_location_dummy/Makefile
  src/plugins/provider_location_freegeoip/Makefile
  src/plugins/provider_location_gpsd/Makefile
  src/plugins/source_dummy/Makefile
  src/plugins/source_gps/Makefile
  src/plugins/source_gsm/Makefile
  src/plugins/source_ntp/Makefile
  src/plugins/sync_time/Makefile
  tests/Makefile
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
echo "  provider_location_gpsd.......................................: $libgps"
echo
echo "  prefix.......................................................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
