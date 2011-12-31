AC_INIT([fsoaudiod], [0.2.0], [smartphones-userland@linuxtogo.org], [fsoaudiod])
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

##############################################################################
# dependency versions
GLIB_REQUIRED=2.26.0
GEE_REQUIRED=0.5.0
FSO_GLIB_REQUIRED=2011.04.12.1
FSO_REQUIRED=0.2.3
ALSA_REQUIRED=0.20
CMTSPEECHDATA_REQUIRED=2.1.1

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
# alsa
PKG_CHECK_MODULES(ALSA,
  alsa >= $ALSA_REQUIRED)
AC_SUBST(ALSA_CFLAGS)
AC_SUBST(ALSA_LIBS)

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
# fso
PKG_CHECK_MODULES(FSO,
  fsoframework-2.0 >= $FSO_REQUIRED
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

##############################################################################
# optional feature: GSM voice call audio using libcmtspeechdata
AC_ARG_ENABLE(cmtspeechdata,
  [  --enable-cmtspeechdata  Enable building the gsm voicecall plugin using libcmtspeechdata (default=disabled)],
  [cmtspeechdata=$enableval],
  [cmtspeechdata="no"])

if test x$cmtspeechdata = "xyes"; then
    PKG_CHECK_MODULES(CMTSPEECHDATA,
      libcmtspeechdata >= $CMTSPEECHDATA_REQUIRED)
AC_SUBST(CMTSPEECHDATA_CFLAGS)
AC_SUBST(CMTSPEECHDATA_LIBS)

fi
AM_CONDITIONAL( [WANT_CMTSPEECHDATA], [test x"$cmtspeechdata" = x"yes"])

##############################################################################
# check for debugging
AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [debug=$enableval],
  [debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$debug" = x"yes"])

##############################################################################
# git version
GITV=`cat ../.git/refs/heads/master || echo "unknown"`
AC_DEFINE_UNQUOTED([PACKAGE_GITV], ["${GITV}"], [git version])

##############################################################################
# datadir
if test "x$prefix" != "xNONE"; then
  pkgdatadir='${prefix}/share/fsoaudiod'
else
  pkgdatadir='/usr/local/share/fsoaudiod'
fi
eval PACKAGE_DATADIR="${pkgdatadir}"
AC_DEFINE_UNQUOTED([PACKAGE_DATADIR], ["${PACKAGE_DATADIR}"], [Shared data directory])

AC_CONFIG_FILES([
  Makefile
  conf/Makefile
  conf/default/Makefile
  conf/palm_pre/Makefile
  conf/palm_pre/audio-scripts/Makefile
  conf/nokia_n900/Makefile
  conf/openmoko_gta/Makefile
  conf/herring/Makefile
  conf/herring/alsa-default/Makefile
  data/Makefile
  data/org.freesmartphone.oaudiod.service
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/alsa_hooks/Makefile
  src/alsa_hooks/session/Makefile
  src/plugins/Makefile
  src/plugins/gsmvoice_alsa_cmtspeechdata/Makefile
  src/plugins/manager/Makefile
  src/plugins/router_palmpre/Makefile
  src/plugins/router_alsa/Makefile
  src/plugins/streamcontrol_alsa/Makefile
  src/plugins/sessionpolicy_default/Makefile
  src/plugins/system_integration/Makefile
])

##############################################################################
# Info
AC_OUTPUT
echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION-$GITV"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options:"
echo
echo "  gsmvoice_alsa_cmtspeechdata:.........: $cmtspeechdata"
echo
echo "  debug build..........................: $debug"
echo
echo "  prefix...............................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
