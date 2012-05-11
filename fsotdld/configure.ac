m4_define([fsotdld_released], [0])
m4_define([fsotdld_base_version], [0.11.0])
m4_define([fsotdld_maybe_gitrev], m4_if(fsotdld_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsotdld_version], m4_if(fsotdld_released, [1], [fsotdld_base_version], [fsotdld_base_version-fsotdld_maybe_gitrev]))

AC_INIT([fsotdld], fsotdld_version, [smartphones-userland@linuxtogo.org], [fsotdld])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREREQ([2.65])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2 no-dist-gzip tar-ustar])
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
m4_if(fsotdld_released, [1], [],
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
SOUP_REQUIRED=2.29
JSON_REQUIRED=0.10.2
FSO_GLIB_REQUIRED=2012.04.18.1
FSO_REQUIRED=0.11.0

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

PKG_CHECK_MODULES(SOUP,
  libsoup-2.4 >= $SOUP_REQUIRED)
AC_SUBST(SOUP_CFLAGS)
AC_SUBST(SOUP_LIBS)

PKG_CHECK_MODULES(JSON,
  json-glib-1.0 >= $JSON_REQUIRED)
AC_SUBST(JSON_CFLAGS)
AC_SUBST(JSON_LIBS)

PKG_CHECK_MODULES(FSO,
  fsobasics-2.0 >= $FSO_REQUIRED
  fsoframework-2.0 >= $FSO_REQUIRED
  fsotransport-2.0 >= $FSO_REQUIRED
  fsoresource-2.0  >= $FSO_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

PKG_CHECK_MODULES(FSO_GLIB,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED)

#########################################################################################
# optional feature: gpsd
#########################################################################################

AC_ARG_ENABLE(provider-libgps,
  AS_HELP_STRING([--enable-provider-libgps], [Enable building the libgps location provider (default=disabled)]),
  [libgps=$enableval],
  [libgps="no"])

if test x$libgps = x"yes"; then
    # libgps
    PKG_CHECK_MODULES(GPS,
      libgps >= 2.96)
    AC_SUBST(GPS_CFLAGS)
    AC_SUBST(GPS_LIBS)
fi
AM_CONDITIONAL( [WANT_LIBGPS], [test x"$libgps" = x"yes"])

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [enable_debug=$enableval],
  [enable_debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$enable_debug" = x"yes"])

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

AC_CONFIG_FILES([
  Makefile
  conf/Makefile
  conf/default/Makefile
  conf/openmoko_gta/Makefile
  conf/GTA04/Makefile
  conf/htc_qualcomm_dream/Makefile
  conf/htcleo/Makefile
  conf/nexusone/Makefile
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
  src/plugins/source_gpsddbus/Makefile
  src/plugins/sync_time/Makefile
  tests/Makefile
  vapi/Makefile
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
echo "  provider_location_gpsd..: $libgps"
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
