m4_define([fsoaudiod_released], [0])
m4_define([fsoaudiod_base_version], [0.11.0])
m4_define([fsoaudiod_maybe_gitrev], m4_if(fsoaudiod_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsoaudiod_version], m4_if(fsoaudiod_released, [1], [fsoaudiod_base_version], [fsoaudiod_base_version-fsoaudiod_maybe_gitrev]))

AC_INIT([fsoaudiod], fsoaudiod_version, [smartphones-userland@linuxtogo.org], [fsoaudiod])
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
FSO_GLIB_REQUIRED=2012.04.18.1
FSO_REQUIRED=0.10.0
ALSA_REQUIRED=0.20
CMTSPEECHDATA_REQUIRED=2.1.1

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

PKG_CHECK_MODULES(ALSA,
  alsa >= $ALSA_REQUIRED)
AC_SUBST(ALSA_CFLAGS)
AC_SUBST(ALSA_LIBS)

PKG_CHECK_MODULES(FSO,
  fsoframework-2.0 >= $FSO_REQUIRED
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

#########################################################################################
# dbus conf directory
#########################################################################################

DBUS_DIR="`$PKG_CONFIG --variable=sysconfdir dbus-1`"
if (test -z "{DBUS_DIR}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="$DBUS_DIR/dbus-1"
fi
AC_SUBST(DBUS_DIR)

#########################################################################################
# dbus service directory
#########################################################################################

DBUS_SERVICE_DIR="`$PKG_CONFIG --variable=session_bus_services_dir dbus-1`"
if (test -z "{DBUS_SERVICE_DIR}"); then
  DBUS_SERVICE_DIR="${datadir}/dbus-1/services"
fi
AC_SUBST(DBUS_SERVICE_DIR)

#########################################################################################
# optional feature: GSM voice call audio using libcmtspeechdata
#########################################################################################

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

#########################################################################################
# optional feature: GSM voice call audio forwarding using libsamplerate
#########################################################################################

AC_ARG_ENABLE(samplerate,
  [  --enable-samplerate  Enable building the gsm voicecall plugin using libsamplerate (default=disabled)],
  [samplerate=$enableval],
  [samplerate="no"])

if test x$samplerate = "xyes"; then
    PKG_CHECK_MODULES(SAMPLERATE,
      [samplerate])
AC_SUBST(SAMPLERATE_CFLAGS)
AC_SUBST(SAMPLERATE_LIBS)

fi
AM_CONDITIONAL( [WANT_SAMPLERATE], [test x"$samplerate" = x"yes"])

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [enable_debug=$enableval],
  [enable_debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$enable_debug" = x"yes"])

#########################################################################################
# datadir
#########################################################################################

if test "x$prefix" != "xNONE"; then
  pkgdatadir='${prefix}/share/fsoaudiod'
else
  pkgdatadir='/usr/local/share/fsoaudiod'
fi
eval PACKAGE_DATADIR="${pkgdatadir}"
AC_DEFINE_UNQUOTED([PACKAGE_DATADIR], ["${PACKAGE_DATADIR}"], [Shared data directory])

#########################################################################################
# output
#########################################################################################

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
  conf/GTA04/Makefile
  data/Makefile
  data/org.freesmartphone.oaudiod.service
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/alsa_hooks/Makefile
  src/alsa_hooks/session/Makefile
  src/plugins/Makefile
  src/plugins/gsmvoice_alsa_cmtspeechdata/Makefile
  src/plugins/gsmvoice_alsa_forwarder/Makefile
  src/plugins/manager/Makefile
  src/plugins/router_palmpre/Makefile
  src/plugins/router_alsa/Makefile
  src/plugins/streamcontrol_alsa/Makefile
  src/plugins/sessionpolicy_default/Makefile
  src/plugins/system_integration/Makefile
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
echo "  gsmvoice_alsa_cmtspeechdata:.........: $cmtspeechdata"
echo
echo "  gsmvoice_alsa_forwarder:.............: $samplerate"
echo
echo "  Vala.................................: $enable_vala"
echo
echo "  Vala Compiler........................: ${VALAC}"
echo
echo "  debug build..........................: $enable_debug"
echo
echo "  prefix...............................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
