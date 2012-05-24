m4_define([fsogsmd_released], [0])
m4_define([fsogsmd_base_version], [0.11.0])
m4_define([fsogsmd_maybe_gitrev], m4_if(fsogsmd_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsogsmd_version], m4_if(fsogsmd_released, [1], [fsogsmd_base_version], [fsogsmd_base_version-fsogsmd_maybe_gitrev]))

AC_INIT([fsodeviced], fsogsmd_version, [smartphones-userland@linuxtogo.org], [fsodeviced])
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
m4_if(fsodeviced_released, [1], [],
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
FSO_GLIB_REQUIRED=2012.05.24.1
FSO_REQUIRED=0.11.0
ALSA_REQUIRED=0.20
CANBERRA_REQUIRED=0.17
GSTREAMER_REQUIRED=0.10.20

PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(FSO,
  fso-glib-1.0 >= $FSO_REQUIRED
  fsoresource-2.0 >= $FSO_REQUIRED
  fsotransport-2.0 >= $FSO_REQUIRED
  fsoframework-2.0 >= $FSO_REQUIRED
  fsosystem-2.0 >= $FSO_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

PKG_CHECK_MODULES(ALSA,
  alsa >= $ALSA_REQUIRED)
AC_SUBST(ALSA_CFLAGS)
AC_SUBST(ALSA_LIBS)

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
# optional feature: fsoresource integration
#########################################################################################

AC_ARG_ENABLE(resource_integration,
  AS_HELP_STRING([--disable-resource-integration],[Disable FSO resource integration (default=enabled)]),
  [fsoresource=$enableval],
  [fsoresource="yes"])

AM_CONDITIONAL( [WANT_FSORESOURCE], [test x"$fsoresource" = x"yes"])

#########################################################################################
# optional feature: kernel26_rfkill
#########################################################################################

AC_ARG_ENABLE(kernel26_rfkill,
  AS_HELP_STRING([--disable-kernel26-rfkill],[Disable building the rfkill power control plugin (default=enabled)]),
  [rfkill=$enableval],
  [rfkill="yes"])

if test x$rfkill = "xyes"; then
    # linux/rfkill.h
    AC_CHECK_HEADER([linux/rfkill.h],,[AC_MSG_ERROR([cannot find linux/rfkill.h (linux-libc-headers too old?) necessary for kernel26_rfkill])])
fi
AM_CONDITIONAL( [WANT_RFKILL], [test x"$rfkill" = x"yes"])

#########################################################################################
# optional feature: player_canberra
#########################################################################################

AC_ARG_ENABLE(player_canberra,
  AS_HELP_STRING([--enable-player-canberra], [Enable building the libcanberra audio player plugin (default=disabled)]),
  [canberra=$enableval],
  [canberra="no"])

if test x$canberra = "xyes"; then
    # libcanberra
    PKG_CHECK_MODULES(CANBERRA,
      libcanberra >= $CANBERRA_REQUIRED)
    AC_SUBST(CANBERRA_CFLAGS)
    AC_SUBST(CANBERRA_LIBS)
    # sys/eventfd.h
    AC_CHECK_HEADER([sys/eventfd.h],,[AC_MSG_ERROR([cannot find all headers (glibc too old?) necessary for player-canberra])])
fi
AM_CONDITIONAL( [WANT_CANBERRA], [test x"$canberra" = x"yes"])

#########################################################################################
# optional feature: player_gstreamer
#########################################################################################

AC_ARG_ENABLE(player_gstreamer,
  AS_HELP_STRING([--enable-player-gstreamer],[Enable building the gstreamer audio player plugin (default=disabled)]),
  [gstreamer=$enableval],
  [gstreamer="no"])

if test x$gstreamer = "xyes"; then
    # gstreamer
    PKG_CHECK_MODULES(GSTREAMER,
      gstreamer-0.10 >= $GSTREAMER_REQUIRED)
    AC_SUBST(GSTREAMER_CFLAGS)
    AC_SUBST(GSTREAMER_LIBS)
fi
AM_CONDITIONAL( [WANT_GSTREAMER], [test x"$gstreamer" = x"yes"])

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  AS_HELP_STRING([--enable-debug],[Enable debug build (default=disabled)]),
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
  vapi/Makefile
  conf/Makefile
  conf/default/Makefile
  conf/htc_qualcomm_dream/Makefile
  conf/htc_qualcomm_dream/alsa-default/Makefile
  conf/htc_qualcomm_msm/Makefile
  conf/htcleo/Makefile
  conf/motorola_ezx/Makefile
  conf/nexusone/Makefile
  conf/nokia_n900/Makefile
  conf/nokia_n900/alsa-default/Makefile
  conf/openmoko_gta/Makefile
  conf/openmoko_gta/alsa-2.6.29/Makefile
  conf/openmoko_gta/alsa-2.6.31/Makefile
  conf/openmoko_gta/alsa-2.6.34/Makefile
  conf/openmoko_gta/alsa-2.6.39/Makefile
  conf/GTA04/Makefile
  conf/GTA04/alsa-3.2/Makefile
  conf/palm_pre/Makefile
  conf/herring/Makefile
  conf/herring/alsa-default/Makefile
  data/Makefile
  data/org.freesmartphone.odeviced.service
  src/Makefile
  src/3rdparty/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/plugins/Makefile
  src/plugins/accelerometer/Makefile
  src/plugins/accelerometer_kxsd9/Makefile
  src/plugins/accelerometer_lis302/Makefile
  src/plugins/ambientlight_n900/Makefile
  src/plugins/audio/Makefile
  src/plugins/backlight_omappanel/Makefile
  src/plugins/gpio_input/Makefile
  src/plugins/dummy_input/Makefile
  src/plugins/kernel26_cpufreq/Makefile
  src/plugins/kernel26_display/Makefile
  src/plugins/kernel26_firmwareloader/Makefile
  src/plugins/kernel26_leds/Makefile
  src/plugins/kernel26_powersupply/Makefile
  src/plugins/kernel26_rfkill/Makefile
  src/plugins/kernel26_rtc/Makefile
  src/plugins/kernel_idle/Makefile
  src/plugins/kernel_info/Makefile
  src/plugins/kernel_input/Makefile
  src/plugins/n900_powercontrol/Makefile
  src/plugins/openmoko_powercontrol/Makefile
  src/plugins/gta04_quirks/Makefile
  src/plugins/palmpre_quirks/Makefile
  src/plugins/herring_quirks/Makefile
  src/plugins/powercontrol_ifconfig/Makefile
  src/plugins/player_alsa/Makefile
  src/plugins/player_canberra/Makefile
  src/plugins/player_gstreamer/Makefile
  src/plugins/powersupply_n900/Makefile
  src/plugins/proximity_n900/Makefile
  src/plugins/router_alsa/Makefile
  src/plugins/router_qdsp5/Makefile
  src/plugins/thinkpad_powercontrol/Makefile
  src/plugins/vibrator_ledclass/Makefile
  src/plugins/vibrator_omapvibe/Makefile
  src/plugins/vibrator_timedoutputclass/Makefile
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
echo "  FSO resource integration.............: $fsoresource"
echo
echo "  kernel26_rfkill......................: $rfkill"
echo "  player_canberra......................: $canberra"
echo "  player_gstreamer.....................: $gstreamer"
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
