AC_INIT([fsodeviced], [0.9.5], [smartphones-userland@linuxtogo.org], [fsodeviced])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

VALA_REQUIRED=0.12.1
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
m4_ifdef([AM_PROG_VALAC], [AM_PROG_VALAC([$VALA_REQUIRED])])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

##############################################################################
# required versions
GLIB_REQUIRED=2.26.0
GEE_REQUIRED=0.5.0
FSO_GLIB_REQUIRED=2010.05.11.2
FSO_FRAMEWORK_REQUIRED=0.2.4
FSO_TRANSPORT_REQUIRED=0.9.7
FSO_RESOURCE_REQUIRED=0.1.0
FSO_SYSTEM_REQUIRED=0.1.0
ALSA_REQUIRED=0.20
CANBERRA_REQUIRED=0.17
GSTREAMER_REQUIRED=0.10.20

##############################################################################
# glib and friends + gee
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

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
# fso-glib and framework
PKG_CHECK_MODULES(FSO,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED
  fsoresource-2.0 >= $FSO_RESOURCE_REQUIRED
  fsotransport-2.0 >= $FSO_TRANSPORT_REQUIRED
  fsoframework-2.0 >= $FSO_FRAMEWORK_REQUIRED
  fsosystem-2.0 >= $FSO_SYSTEM_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

##############################################################################
# alsa
PKG_CHECK_MODULES(ALSA,
  alsa >= $ALSA_REQUIRED)
AC_SUBST(ALSA_CFLAGS)
AC_SUBST(ALSA_LIBS)

##############################################################################
# optional feature: fsoresource integration
AC_ARG_ENABLE(resource_integration,
  AS_HELP_STRING([--disable-resource-integration],[Disable FSO resource integration (default=enabled)]),
  [fsoresource=$enableval],
  [fsoresource="yes"])

AM_CONDITIONAL( [WANT_FSORESOURCE], [test x"$fsoresource" = x"yes"])

##############################################################################
# optional feature: kernel26_rfkill
AC_ARG_ENABLE(kernel26_rfkill,
  AS_HELP_STRING([--enable-kernel26-rfkill],[Enable building the rfkill power control plugin (default=disabled)]),
  [rfkill=$enableval],
  [rfkill="no"])

if test x$rfkill = "xyes"; then
    # linux/rfkill.h
    AC_CHECK_HEADER([linux/rfkill.h],,[AC_MSG_ERROR([cannot find linux/rfkill.h (linux-libc-headers too old?) necessary for kernel26_rfkill])])
fi
AM_CONDITIONAL( [WANT_RFKILL], [test x"$rfkill" = x"yes"])

##############################################################################
# optional feature: player_canberra
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

##############################################################################
# optional feature: player_gstreamer
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

# No longer necessary, we ship our own copy of the header
##############################################################################
# i2c-tools
#AC_CHECK_HEADER(linux/i2c-dev.h, ,
#    [AC_MSG_ERROR([Could not find linux/i2c-dev.h...please install i2c-tools])])
#AC_LINK_IFELSE([AC_LANG_PROGRAM([#include <linux/i2c-dev.h>
#  void test() { int foo = i2c_smbus_read_byte_data( 0, 0 ); } ])],,
#  [AC_MSG_ERROR([Could not find i2c functions in linux/i2c-dev.h...please install i2c-tools, libi2c-dev, etc.])])

##############################################################################
# check for debugging
AC_ARG_ENABLE(debug,
  AS_HELP_STRING([--enable-debug],[Enable debug build (default=disabled)]),
  [debug=$enableval],
  [debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$debug" = x"yes"])

##############################################################################
# git version
GITV=`cat ../.git/refs/heads/master || echo "unknown"`
AC_DEFINE_UNQUOTED([PACKAGE_GITV], ["${GITV}"], [git version])

##############################################################################
# output
AC_CONFIG_FILES([
  Makefile
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
  conf/palm_pre/Makefile
  conf/herring/Makefile
  data/Makefile
  data/org.freesmartphone.odeviced.service
  src/Makefile
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
  src/plugins/gta04_powercontrol/Makefile
  src/plugins/palmpre_quirks/Makefile
  src/plugins/powercontrol_ifconfig/Makefile
  src/plugins/player_alsa/Makefile
  src/plugins/player_canberra/Makefile
  src/plugins/player_gstreamer/Makefile
  src/plugins/powersupply_n900/Makefile
  src/plugins/proximity_palmpre/Makefile
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
echo "  FSO resource integration.............: $fsoresource"
echo
echo "  kernel26_rfkill......................: $rfkill"
echo "  player_canberra......................: $canberra"
echo "  player_gstreamer.....................: $gstreamer"
echo
echo "  debug build..........................: $debug"
echo
echo "  prefix...............................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
